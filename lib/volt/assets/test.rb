require 'sass'

sass_engine = Sass::Engine.new(template, syntax: :scss, filename: 'cool.css.scss', sourcemap: true); output =
sass_engine.render_with_sourcemap('/source_maps/')
