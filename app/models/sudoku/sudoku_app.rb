require_relative "../sudoku"

# Backward-compatible alias for older requires/constants after renaming SudokuApp -> Sudoku.
Sudoku::SudokuApp = Sudoku unless defined?(Sudoku::SudokuApp)
