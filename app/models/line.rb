class Line < Group
    def initialize(matrix_vector)
        @vector = matrix_vector
        @cells = gather_cells
        @values = cells.collect(&:value)
    end

    def gather_cells
        cells = []
        @vector.each do |cell|
            cells << cell
        end
        cells
    end
end
