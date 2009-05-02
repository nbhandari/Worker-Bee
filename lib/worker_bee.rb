require 'thread'

class WorkerBee
  VERSION = '1.0.0'
  
  class << self; attr_accessor :workitems_list end  
  
  @@white_space = '  '
  
  def self.white_space
    @@white_space
  end
    
  class WorkItem
    attr_accessor :symbol, :dependencies, :block
    def initialize symbol, *args, &block      
      @symbol = symbol
      @dependencies = Array.new
      args.each do |arg|
        @dependencies << arg
      end
      @block = block
    end    
  end
  
  def self.recipe(&block)
    raise ArgumentError unless block_given?
    @workitems_list = Hash.new
    instance_eval(&block)
  end
  
  def self.work(symbol, *args, &block)
    workitem = WorkItem.new symbol, *args, &block
    if @workitems_list.has_key? symbol then
      raise ArgumentError
    else
      @workitems_list[symbol] = workitem
    end
  end
  
  def self.run(symbol)
    finished_dependencies = Hash.new
    @mutex = Mutex.new
    recursive_run @workitems_list[symbol], finished_dependencies, 0
  end
  
  private
  def self.recursive_run workitem, finished_deps, level
    threads = []
    puts "#{@@white_space * level}running #{workitem.symbol}"
    workitem.dependencies.each do |dep|
      threads << Thread.new do
        key_present = false
        @mutex.synchronize {
          key_present = finished_deps.has_key?(dep)
          if !key_present then
            finished_deps[dep] = Thread.current
          end
        }
        
        if !key_present then
          recursive_run @workitems_list[dep], finished_deps, level+1
        else
          finished_deps[dep].join
          puts "#{@@white_space * (level+1)}not running #{@workitems_list[dep].symbol} - already met dependency" 
        end
      end
    end
    
    threads.each { |thread| thread.join }        
    workitem.block.call    
  end  
end