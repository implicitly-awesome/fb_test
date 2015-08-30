require 'minitest/autorun'

class Array
  def missed_items(variant: 1)
    return [] if self.empty? || self.count == 1
    max_item = self.max
    # actually in task description min_item always == 1, but let's pick it dynamically
    min_item = self.min
    # make an array of full sequence of numbers
    full_array = (min_item..max_item).to_a
    case variant
      # based on plain ruby array substraction
      when 1
        # return the difference
        full_array - self

      # based on sums & sums of squares differences and searching
      when 2
        result = []
        # calculate sums on both arrays: sum of items sqrt & sum of items
        self_sum = self.inject(:+)
        self_sqrt_sum = self.inject { |sum, x| sum+=x**2 }
        full_array_sum = full_array.inject(:+)
        full_array_sqrt_sum = full_array.inject { |sum, x| sum+=x**2 }

        # calculate the differences of sums
        sum_diff = full_array_sum - self_sum
        sqrt_sum_diff = full_array_sqrt_sum - self_sqrt_sum

        # take a sqrt root from sqrt sum difference
        sqrt_sum_diff_root = Math.sqrt(sqrt_sum_diff)

        # if sqrt_sum_diff_root is an integer number - then missed only that number
        if sqrt_sum_diff_root%1 == 0
          return result << sqrt_sum_diff_root
          # if not - check: is calculated and floored root exists in self array
          # - yes - decrease num by 1 and check again
          # - no - this is our first missed number
        else
          result << find_and_return(sqrt_sum_diff_root.floor)
        end
        # the second missed number = plain sum difference minus our first number (and we're not interested in zeros)
        result << (sum_diff - result.first) if (sum_diff - result.first) > 0

      # based on sums & sums of squares differences and quadratic equation solving
      when 3
        # calculate sums on both arrays: sum of items sqrt & sum of items
        self_sum = self.inject(:+)
        self_sqrt_sum = self.inject { |sum, x| sum+=x**2 }
        full_array_sum = full_array.inject(:+)
        full_array_sqrt_sum = full_array.inject { |sum, x| sum+=x**2 }

        # calculate the differences of sums
        sum_diff = full_array_sum - self_sum
        sqrt_sum_diff = full_array_sqrt_sum - self_sqrt_sum
        # two missed numbers x**2+y**2 == sqrt_sum_diff, x+y == sum_diff => y == sum_diff-x => x**2+(sum_diff-x)**2 == sqrt_sum_diff
        # calculate a,b,c for quadratic equation ax**2+bx+c == 0
        a = 2
        b = -2*sum_diff
        c = (sum_diff**2) - sqrt_sum_diff
        solution = solve_quadratic_equation(a, b, c)
        [solution, sum_diff-solution]
      # based on dividing until pair comparison
      when 4
        divide_and_return(self).flatten.compact
      else
        []
    end
  end

  private

  def find_and_return(item)
    if self.include? item
      find_and_return item-1
    else
      item
    end
  end

  # we're interested only in positive numbers, so sign doesn't matter
  def solve_quadratic_equation(a, b, c)
    discriminant = (b**2) - (4*a*c)
    ((b*-1)+Math.sqrt(discriminant))/(2*a).to_i
  end

  def divide_and_return(arr)
    if arr.count == 2
      diff = arr.last - arr.first
      return [arr.last - 1] if diff == 2
      return [arr.last - 2, arr.last - 1] if diff > 2
    else
      divide_index = arr.count/2
      arr_l = arr[0..divide_index]
      arr_r = arr[divide_index..-1]
      [divide_and_return(arr_l), divide_and_return(arr_r)]
    end
  end
end


# 1_000_000 numbers
# var 1 - 0.890000   0.040000   0.930000 (  0.935603)
# var 2 - 0.580000   0.000000   0.580000 (  0.595798)
# var 3 - 0.570000   0.000000   0.570000 (  0.585820)
# var 4 - 1.610000   0.040000   1.650000 (  1.649553)

# 10_000_000 numbers
# var 1 - 10.850000   0.480000  11.330000 ( 11.334556)
# var 2 - 7.300000   0.120000   7.420000 (  7.428582)
# var 3 - 7.200000   0.110000   7.310000 (  7.312020)
# var 4 - 16.880000   0.500000  17.380000 ( 17.392838)


class Tests < Minitest::Test
  def test_common_array
    assert_equal [3, 6], [1, 2, 4, 5, 7].missed_items(variant: 1)
    # the result of the second variant has desc order
    assert_equal [6, 3], [1, 2, 4, 5, 7].missed_items(variant: 2)
    # the result of the third variant has desc order
    assert_equal [6, 3], [1, 2, 4, 5, 7].missed_items(variant: 3)
    assert_equal [3, 6], [1, 2, 4, 5, 7].missed_items(variant: 4)
  end

  def test_empty_array
    assert_equal [], [].missed_items(variant: 1)
    assert_equal [], [].missed_items(variant: 2)
    assert_equal [], [].missed_items(variant: 3)
    assert_equal [], [].missed_items(variant: 4)
  end

  def test_one_item
    assert_equal [], [1].missed_items(variant: 1)
    assert_equal [], [1].missed_items(variant: 2)
    assert_equal [], [1].missed_items(variant: 3)
    assert_equal [], [1].missed_items(variant: 4)
  end

  def test_two_items
    assert_equal [2, 3], [1, 4].missed_items(variant: 1)
    # the result of the second variant has desc order
    assert_equal [3, 2], [1, 4].missed_items(variant: 2)
    # the result of the third variant has desc order
    assert_equal [3, 2], [1, 4].missed_items(variant: 3)
    assert_equal [2, 3], [1, 4].missed_items(variant: 4)
  end

  def test_big_sequence
    assert_equal [112, 5233], ((1..1_000_000).to_a-[112, 5233]).missed_items(variant: 1)
    # the result of the second variant has desc order
    assert_equal [5233, 112], ((1..1_000_000).to_a-[112, 5233]).missed_items(variant: 2)
    # the result of the third variant has desc order
    assert_equal [5233, 112], ((1..1_000_000).to_a-[112, 5233]).missed_items(variant: 3)
    assert_equal [112, 5233], ((1..1_000_000).to_a-[112, 5233]).missed_items(variant: 4)
  end
end