# Revisão do plano "Surface Selection" frente ao iOS 27

Data: 2026-10-24 · Plano revisado: `SURFACE_SELECTION_IMPLEMENTATION_PLAN.md` (2026-08-04)

## Fontes usadas

- SDK instalado: Xcode 27.0 (27A5228h), `iPhoneOS27.0.sdk`.
- Interface pública do RoomPlan: `.../iPhoneOS27.0.sdk/System/Library/Frameworks/RoomPlan.framework/Modules/RoomPlan.swiftmodule/arm64e-apple-ios.swiftinterface` (811 linhas).
- Headers do SceneKit: `.../iPhoneOS27.0.sdk/System/Library/Frameworks/SceneKit.framework/Headers/`.
- Código do plugin: `packages/roomplan_flutter/ios/...` e `lib/src/mapper.dart`.
- Nenhuma página web consultada (notas de versão e sessões WWDC26 não verificadas). Nada foi compilado.

## Resposta curta

A API do RoomPlan **não mudou no iOS 27**. Na interface do SDK 27, os `@available` são só `iOS 16.0` (34) e `iOS 17.0` (73); não existe nenhum símbolo do iOS 18 ou posterior, e nada está marcado como `deprecated` ou `obsoleted`. O iOS 27 não deixa o plano velho.

Mas a revisão achou **um erro que já estava no plano antes do iOS 27**: ele usa APIs do iOS 17 num plugin cujo mínimo é o iOS 16.

## Item por item

| Item do plano | Situação | Evidência |
|---|---|---|
| `CapturedRoom.Surface.identifier`, `dimensions` (`simd_float3`), `transform` (`simd_float4x4`), `confidence`, `category` | Continua válido (iOS 16) | swiftinterface l.392-404 |
| `Surface.parentIdentifier` (fase 1, liga a abertura à parede) | **Válido, mas é iOS 17+**. O plano o chama sem `#available`; com o mínimo em 16.0 isso **não compila** | swiftinterface l.414-415 `@available(iOS 17.0, *) public var parentIdentifier: UUID?` |
| Achado 1: parede plana com `dimensions` = (largura, altura, 0) | Continua válido; o conversor já trata `x` como comprimento da parede | `RoomPlanJSONConverter.swift:86` `halfLength = wall.dimensions.x / 2.0` |
| Achado 2: aberturas emitidas como listas irmãs, não aninhadas | Confirmado no código atual | `mapper.dart:102-119` |
| Achado 3: `points` sempre vazio, "a geometria só vem de transform + dimensions" | **Desatualizado**. Desde o iOS 17 existe `Surface.polygonCorners` (contorno real) e `Surface.curve` (parede curva, iOS 16). O plano ignora as duas | swiftinterface l.411 `curve`, l.418-419 `@available(iOS 17.0, *) polygonCorners: [simd_float3]` |
| Piso e teto "sintéticos", montados a partir das paredes | **Existe API nativa mais simples**: `CapturedRoom.floors` (iOS 17) entrega o piso real. Não há lista de teto no RoomPlan | swiftinterface l.304-305 `@available(iOS 17.0, *) public var floors` |
| `CapturedRoom.sections` / `story` (cômodos e andares) | API nova desde o iOS 17, ausente do plano. Útil para a lacuna "parede compartilhada" e para várias salas | swiftinterface l.314-319 |
| `CapturedStructure` (junção de vários scans) | iOS 17, ausente do plano. Não resolve a identidade entre scans (lacuna da fase 8 continua) | swiftinterface l.248-280 |
| UUID novo a cada scan (fase 8, limpar seleção no rescan) | Continua válido; nenhuma API de identidade estável foi adicionada | sem símbolo novo na interface |
| SceneKit: `SCNView`, `SCNScene`, `SCNBox`, `SCNNode.simdTransform`, `allowsCameraControl`, `autoenablesDefaultLighting`, `hitTest` (fase 3) | Disponível e **sem marca `deprecated`** nos headers do SDK 27 (só as APIs OpenGL estão deprecadas) | `SceneKit.framework/Headers/SCNView.h:59`, `SceneKitTypes.h:24-25` |
| Status do SceneKit na Apple | **Não verificado**. Lembro de a Apple ter colocado o SceneKit em modo só-manutenção na WWDC25, recomendando o RealityKit, mas isso não aparece nos headers e não conferi online | — |
| `FlutterPlatformViewFactory`, `registrar.register(_:withId:)`, `UiKitView` (fases 3-4) | API do Flutter, não da Apple; fora do escopo do iOS 27. **Não verificado** contra a versão atual do Flutter | — |
| "O viewer não depende do RoomPlan e roda em qualquer iOS" | Continua válido | — |

## O plugin hoje com o iOS 27

- Mínimo declarado: iOS 16.0 (`ios/roomplan_flutter.podspec:17` e `Package.swift` `.iOS("16.0")`).
- O plugin usa só APIs do iOS 16 (`RoomPlanController.swift:9`, `RoomPlanJSONConverter.swift:7`). Nenhuma delas foi deprecada ou removida no SDK 27, então a inspeção estática não mostra nada que quebre. A compilação não foi verificada, por regra.

## Mudanças recomendadas no plano (recomendação, não decisão)

1. **Fase 1**: decidir entre subir o mínimo do plugin para o iOS 17, ou envolver `parentIdentifier` em `if #available(iOS 17.0, *)` e mandar `nil` no 16. Recomendo subir para o 17: todo aparelho com LiDAR que roda o iOS 16 também recebe o 17, e isso libera também os itens 2 e 3. É uma mudança que quebra compatibilidade, então entra no CHANGELOG da `0.3.0`.
2. **Achado 3 e fase 3**: serializar `polygonCorners` (e `curve`) e desenhar a parede pelo contorno real quando ele existir. Área calculada como largura × altura erra em paredes não retangulares (sob escada, com recorte).
3. **Piso**: trocar o piso sintético por `CapturedRoom.floors` no iOS 17. O teto continua sintético, porque não existe API para ele. Isso diminui a lacuna "piso/teto com eixo trocado".
4. **Lacunas adiadas**: citar `sections`/`story` como caminho futuro para várias salas ou andares. Não resolvem a identidade entre scans.
5. **Fase 3**: registrar o risco do SceneKit. Ou se confirma o status com a Apple e se aceita o SceneKit (o mais simples, funciona hoje), ou se avalia o RealityKit. Recomendo manter o SceneKit no primeiro corte.
6. Antes de fechar o plano, conferir as notas de versão do RoomPlan e do SceneKit para o iOS 27 no developer.apple.com (não feito nesta revisão).
