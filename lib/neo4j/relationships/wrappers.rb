module Neo4j
  module Relationships

    # Wrapper for org.neo4j.graphdb.ReturnableEvaluator
    #
    class ReturnableEvaluator #:nodoc:
      include org.neo4j.graphdb.ReturnableEvaluator if defined? JRUBY_VERSION

      def initialize(proc, raw = false)
        @proc = proc
        @raw = raw
      end

      unless defined? JRUBY_VERSION
        def self.new(proc, raw = false)
           re = super 
           Rjb::bind(re, 'org.neo4j.graphdb.ReturnableEvaluator')
        end
      end
      def isReturnableNode( traversal_position )
        # if the Proc takes one argument that we give it the traversal_position
        result = if @proc.arity == 1
          # wrap the traversal_position in the Neo4j.rb TraversalPostion object
          @proc.call TraversalPosition.new(traversal_position, @raw)
        else # otherwise we eval the proc in the context of the current node
          # do not include the start node
          return false if traversal_position.isStartNode()
          eval_context = Neo4j::load_node(traversal_position.currentNode.getId, @raw)
          eval_context.instance_eval(&@proc)
        end

        # java does not treat nil as false so we need to do it instead
        (result)? true : false
      end
    end


    # Wrapper for the neo4j org.neo4j.graphdb.StopEvalutor interface.
    # Used in the Neo4j Traversers.
    #
    class DepthStopEvaluator #:nodoc:
      include org.neo4j.graphdb.StopEvaluator if defined? JRUBY_VERSION

      def initialize(depth)
        @depth = depth

      end

      def isStopNode(pos)
        pos.depth >= @depth
      end

      def self.new(depth)
        d = super
        Rjb::bind(d, 'org.neo4j.graphdb.StopEvaluator')         
      end unless defined? JRUBY_VERSION
    end
  end


end