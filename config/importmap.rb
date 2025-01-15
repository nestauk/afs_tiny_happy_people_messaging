# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "sortablejs" # @1.15.3
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.11
pin "@stimulus-components/sortable", to: "@stimulus-components--sortable.js" # @5.0.1
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.7/dist/chart.js"
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
