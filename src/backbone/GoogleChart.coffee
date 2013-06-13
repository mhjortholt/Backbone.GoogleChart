class Backbone.GoogleChart extends Backbone.View
  ###
  # Initialize a new GoogleChart object
  # In addition to the default Backbone.View options ( such as id, className etc...)
  # Google.ChartWrapper#options should also be passed using the `chartOptions` key
  #
  # Example:
  #   options = {
  #     chartType: 'ColumnChart',
  #     dataTable: [['Germany', 'USA', 'Brazil', 'Canada', 'France', 'RU'],
  #                [700, 300, 400, 500, 600, 800]],
  #     options: {'title': 'Countries'},
  #   }
  #
  #   graph = new Backbone.GoogleChart({chartOptions: options});
  #
  #   $('body').append( graph.render().el );
  # 
  # For the complete list of options that can be passed through the `chartOptions` attribute
  # https://developers.google.com/chart/interactive/docs/reference#chartwrapperobject
  #
  # Please don't try to pass `containerId`, it will be ignored, instead use the `id` attribute, e.g
  #   graph = new Backbone.GoogleChart({chartOptions: options, id:"MyCustomID"});
  # 
  ###
  initialize: ( options ) ->
    google.load 'visualization', '1', callback: =>
      options.chartOptions? or throw "chartOptions is missing"
      delete options.chartOptions.containerId # Please use `id` to specified the wrapping element id
      @google = google.visualization
      @wrapper = new @google.ChartWrapper options.chartOptions
      ['ready','select', 'error'].map @listen
  
  ###
  # Execute a callback once a given element ID appears in DOM ( mini livequery ).
  #
  # We need it because GoogleChart object only draw itself on DOM elements
  # so we first need to wait for our element to be added to the DOM before
  # we call GoogleChart.draw().
  # 
  # Usage: 
  #   Backbone.GoogleChart.watch("#myid", function() { console.log("I'm in") });
  #   $("body").append("<div id='myid'></div>"); // 'I"m in' should be printed to console
  #
  ###
  @watch: ( id, fn ) =>
    (@_list ||= {})[id] = fn
    return if @_watching
    @_watching = true

    func = =>
      _(@_list).map ( fn, id ) =>
        fn() || delete @_list[id] if $(id)[0]
        if _(@_list).isEmpty()
          @_watching = false
        else
          setTimeout(func, 20)

    setTimeout(func, 20)

  ###
  # Returns the wrapping element id
  # if no id was specified on initialization a random one will be returned
  ###
  id: =>
    @el?.id or @randomID()
    
  ###
  # "Instruct" the current graph instance to draw itself once its visiable on DOM
  # return the current instance 
  ###
  render: =>
    @constructor.watch "##{@el.id}", =>
      @wrapper.draw @el.id
    this
  
  ###
  # Register for ChartWrapper events
  # For the complete event list please look at the events section under
  #  https://developers.google.com/chart/interactive/docs/reference#chartwrapperobject
  # 
  # By default the ready, select and error events are register automatically on initialization
  # so instead of calling this function directly consider this:
  #   graph = new Backbone.GoogleChart({chartOptions: options});
  #   graph.on("select",function(graph) { console.log("Someone click on me!") })
  #   graph.on("error",function(graph) { console.log("Oops") })
  #   graph.on("ready",function(graph) { console.log("I'm ready!") })
  # 
  ###
  listen: ( event ) =>
    @google.events.addListener @wrapper, event, =>
      @trigger event, @wrapper.getChart()

  ###
  # Generate a random ID, gc_XXX
  ###
  randomID: ->
    _.uniqueId "gc_"