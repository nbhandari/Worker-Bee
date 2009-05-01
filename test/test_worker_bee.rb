require 'test/unit'
require 'worker_bee'

class WorkerBee
  class << self; attr_accessor :output_text end
  @output_text = ""
  def self.puts str
    @output_text += str
  end    
end

class TestWorkerBee < Test::Unit::TestCase  
  
  def setup
    @level = 0
    WorkerBee.output_text = ""
    
    @args= Array.new
    @args << :base
    @block = Proc.new { puts "Newly added workitem"}
    
    WorkerBee.recipe do
      work :base do
        @@time_base = Time::now
        sleep 0.1
        "base"
      end
      
      work :dependency_1_1, :base do
        @@time_dependency_1_1= Time::now
        sleep 0.1
        "dependency_1_1"
      end
      
      work :dependency_1_2, :base do
        "dependency_1_2"
        sleep 0.1
        @@time_dependency_1_2= Time::now
      end
      
      work :complex,  :dependency_1_1, :dependency_1_2 do
        "complex"
        sleep 0.1
        @@time_complex= Time::now
      end
    end    
  end
  
  def test_recipe_one_workitem
    WorkerBee.recipe do
      work :one do
        "only one workitem"
      end
    end
    assert_equal 1, WorkerBee.workitems_list.size
  end
  
  def test_recipe_two_workitems
    WorkerBee.recipe do
      work :one do
        "1st workitem"
      end
      work :two do
        "2nd workitem"
      end
    end
    assert_equal 2, WorkerBee.workitems_list.size
  end
  
  def test_recipe_zero_workitems
    WorkerBee.recipe do
    end
    assert_equal 0, WorkerBee.workitems_list.size
  end
  
  def test_work_adds_new_workitem
    workitems_initial = WorkerBee.workitems_list.size    
    
    assert !WorkerBee.workitems_list.has_key?(:newly_added)
    WorkerBee::work(:newly_added, @args, &@block)
    assert_equal workitems_initial+1, WorkerBee.workitems_list.size
    assert WorkerBee.workitems_list.has_key?(:newly_added)
  end
  
  def test_run_base_task
    return_val = WorkerBee.run :base
    assert_equal("base", return_val)
    
    expected_output_text = "#{WorkerBee.white_space * @level}running base"
    assert_equal expected_output_text, WorkerBee.output_text
  end

  def test_run_dependency_1_1_task
    return_val = WorkerBee.run :dependency_1_1
    assert @@time_dependency_1_1 > @@time_base
    
    expected_output_text = "#{WorkerBee.white_space * @level}running dependency_1_1"
    @level += 1
    expected_output_text += "#{WorkerBee.white_space * @level}running base"
    
    assert_equal expected_output_text, WorkerBee.output_text
  end
  
  def test_run_complex_task
    return_val = WorkerBee.run :complex
    
    assert @@time_dependency_1_1 > @@time_base
    assert @@time_dependency_1_2 > @@time_base
    
    assert @@time_complex > @@time_dependency_1_1
    assert @@time_complex > @@time_dependency_1_2
    
    expected_output_text = "#{WorkerBee.white_space * @level}running complex"
    @level += 1
    expected_output_text += "#{WorkerBee.white_space * @level}running dependency_1_1"
    @level += 1
    expected_output_text += "#{WorkerBee.white_space * @level}running base"
    @level -=1
    expected_output_text += "#{WorkerBee.white_space * @level}running dependency_1_2"
    @level += 1
    expected_output_text += "#{WorkerBee.white_space * @level}not running base - already met dependency"

    assert_equal expected_output_text, WorkerBee.output_text
  end
  
end