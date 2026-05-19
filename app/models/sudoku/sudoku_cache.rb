require_relative "../sudoku"

class Sudoku::SudokuCache
  attr_reader :cache

  def initialize(values = {})
      @cache = values
  end

  def [](key)
    @cache[key]
  end

  def []=(key, value)
    @cache[key] = value
  end

  # Generic method to fetch from cache or compute and store the value
  # key: symbol for the cache key
  # &block: logic to compute the value if not cached
  def cache_or_compute(key)
    if @cache[key][:current]
      @cache[key][:value]
    else
      value = yield
      @cache[key][:value] = value
      @cache[key][:current] = true
      value
    end
  end

  def replace_cache(key, value)
    @cache[key][:current] = true
    @cache[key][:value] = value
    value
  end

  def recompute_cache(key)
    @cache[key][:current] = false
    @cache[key][:value] = nil
    value = yield
    @cache[key][:value] = value
    @cache[key][:current] = true
    value
  end

  def bust_cache(key)
    @cache[key][:current] = false
    @cache[key][:value] = nil
  end

  def bust_entire_cache
    @cache.each_key { |key| bust_cache(key) }
  end
end
