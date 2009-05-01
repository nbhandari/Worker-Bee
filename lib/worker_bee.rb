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
    finished_dependencies = Hash.new(false)
    recursive_run @workitems_list[symbol], finished_dependencies, 0
  end
  
  private
  def self.recursive_run workitem, finished_deps, level
    puts "#{@@white_space * level}running #{workitem.symbol}"
    level += 1
    workitem.dependencies.each do |dep|
      if !finished_deps.has_key?(dep)
        recursive_run @workitems_list[dep], finished_deps, level
        finished_deps[dep] = true
      else
        puts "#{@@white_space * level}not running #{@workitems_list[dep].symbol} - already met dependency"
      end
    end
    
    workitem.block.call    
  end  
end