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
        sleep 0.1
        @@time_base = Time::now
        puts " base!"
      end
      
      work :dependency_1_1, :base do
        sleep 0.1
        @@time_dependency_1_1= Time::now
        puts " dependency_1_1!"
      end
      
      work :dependency_1_2, :base do
        sleep 0.1
        @@time_dependency_1_2= Time::now
        puts " dependency_1_2!"
      end
      
      work :complex,  :dependency_1_1, :dependency_1_2 do
        sleep 0.1
        @@time_complex= Time::now
        puts " complex!"
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
    
    expected_output_text = "#{WorkerBee.white_space * @level}running base base!"
    assert_equal expected_output_text, WorkerBee.output_text
  end

  def test_run_dependency_1_1_task
    return_val = WorkerBee.run :dependency_1_1
    assert @@time_dependency_1_1 > @@time_base
    
    expected_output_text = "#{WorkerBee.white_space * @level}running dependency_1_1"
    @level += 1
    expected_output_text += "#{WorkerBee.white_space * @level}running base"
    expected_output_text += " base! dependency_1_1!"
    
    assert_equal expected_output_text, WorkerBee.output_text
  end
  
  def test_run_complex_task
    return_val = WorkerBee.run :complex
    
    assert @@time_dependency_1_1 > @@time_base
    assert @@time_dependency_1_2 > @@time_base
    
    assert @@time_complex > @@time_dependency_1_1
    assert @@time_complex > @@time_dependency_1_2
    
    output_text_complex = "running complex"
    output_text_dependency_1_1 = "running dependency_1_1"
    output_text_base = "running base"
    output_text_dependency_1_2 = "running dependency_1_2"
    output_text_not_running_base = "not running base - already met dependency"
    
    assert_match /#{output_text_complex}(.)*#{output_text_dependency_1_1}/, WorkerBee.output_text
    assert_match /#{output_text_complex}(.)*#{output_text_dependency_1_2}/, WorkerBee.output_text
    assert_match /(#{output_text_dependency_1_1} | #{output_text_dependency_1_2})(.)*#{output_text_base}/, WorkerBee.output_text
    assert_match /#{output_text_base}(.)*#{output_text_not_running_base}/, WorkerBee.output_text
    
    assert_match /#{output_text_base}(.)*base!/, WorkerBee.output_text
    assert_no_match /!(.)*base!/, WorkerBee.output_text
    assert_match /base!(.)*#{output_text_not_running_base}/, WorkerBee.output_text
    assert_match /base!(.)*dependency_1_1!(.)*complex!/, WorkerBee.output_text
    assert_match /base!(.)*dependency_1_2!(.)*complex!/, WorkerBee.output_text
  end
  
end