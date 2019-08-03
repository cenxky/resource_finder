module ResourceFinder
  class Finder
    attr :name, :options

    def initialize(name, options)
      @name = name.to_s
      @options = options
    end

    def call(controller, force = false)
      with_controller(controller) do
        check_action(force) do
          find_record
        end
      end
    end

    def with_controller(controller)
      begin
        @controller = controller
        @params = controller.params

        yield
      ensure
        remove_instance_variable '@controller'
        remove_instance_variable '@params'
      end
    end

    def check_action(skip_check)
      return if options[:lazy] && !skip_check

      action = @params[:action].to_sym
      only_actions = Array.wrap options[:only]
      except_actions = Array.wrap options[:except]

      if (only_actions.empty? && except_actions.empty?) ||
         (only_actions.present? && only_actions.include?(action)) ||
         (except_actions.present? && except_actions.exclude?(action))
         yield
      end
    end

    def model
      options[:model] || name.classify.constantize
    end

    def query
      query_path = options[:query]

      if query_path.nil?
        ctrl_classify_name = @params[:controller].classify.demodulize
        return model.name == ctrl_classify_name ? @params[:id] : @params["#{name}_id"]
      end

      case query_path
      when Proc
        query_path.call(@params)
      when Array
        @params.dig(*query_path)
      when String, Symbol
        @params[query_path]
      end
    end

    def refer(finder_name)
      @controller.instance_variable_get("@#{finder_name}") || @controller.send(:findable, finder_name)
    end

    def find_record
      if options[:of]
        parent = refer options[:of]
        return parent.try(name)
      end

      columns = Array.wrap options[:in] || :id
      sql = columns.map { |column| "#{column} = :value" }.join(' OR ')

      relation = if options[:scope]
        scope = refer options[:scope]
        reflection = scope._reflections.detect do |key, _reflection|
          _reflection.class_name == model.name || key == name.pluralize
        end
        scope.try(reflection.first)
      else
        model
      end

      relation.find_by!([sql, value: query])
    rescue => e
      raise e unless options[:silent]
    end
  end
end
