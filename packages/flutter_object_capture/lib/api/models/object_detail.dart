/// Detail level of the reconstructed model.
///
/// iOS only supports [reduced]; any other level throws
/// `UnsupportedDetailException`. macOS supports every level.
enum ObjectDetail { preview, reduced, medium, full, raw }
