
require "minitest/autorun"
require_relative "../../../app/models/sudoku/sudoku"
require_relative "../../../app/models/sudoku/sudoku_cache"
class Sudoku::SudokuCacheTest < Minitest::Test
  def setup
    values = Hash.new { |h, k| h[k] = { current: false, value: nil } }
    @cache = Sudoku::SudokuCache.new(values)
  end

  def test_cache_or_compute_caches_value
    result = @cache.cache_or_compute(:foo) { 42 }
    assert_equal 42, result
    assert_equal 42, @cache[:foo][:value]
    assert @cache[:foo][:current]
  end

  def test_cache_or_compute_returns_cached_value
    @cache[:foo] = { current: true, value: 99 }
    result = @cache.cache_or_compute(:foo) { 42 }
    assert_equal 99, result
  end

  def test_replace_cache_sets_value
    result = @cache.replace_cache(:bar, 123)
    assert_equal 123, result
    assert_equal 123, @cache[:bar][:value]
    assert @cache[:bar][:current]
  end

  def test_recompute_cache_forces_recompute
    @cache[:baz] = { current: true, value: 1 }
    result = @cache.recompute_cache(:baz) { 55 }
    assert_equal 55, result
    assert_equal 55, @cache[:baz][:value]
    assert @cache[:baz][:current]
  end

  def test_bust_cache_resets_cache_entry
    @cache[:qux] = { current: true, value: 7 }
    @cache.bust_cache(:qux)
    refute @cache[:qux][:current]
    assert_nil @cache[:qux][:value]
  end

  def test_bust_entire_cache_resets_all_entries
    @cache[:a] = { current: true, value: 1 }
    @cache[:b] = { current: true, value: 2 }
    @cache.bust_entire_cache
    refute @cache[:a][:current]
    refute @cache[:b][:current]
    assert_nil @cache[:a][:value]
    assert_nil @cache[:b][:value]
  end
end
