const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'bbc-blue': '#1079EB',
        'bbc-dark-blue': '#0561c9',
        'bbc-yellow': '#FFE727',
        'bbc-yellow-50': '#fffde9',
        'bbc-purple': '#4505A8',
        'bbc-purple-50': '#dacdee',
        'bbc-pink': '#FF92DB',
        'bbc-pink-50': '#ffe9f8',
        'bbc-red': '#E9212D',
        'bbc-orange': '#FF7300',
        'bbc-orange-50': '#ffe3cc',
        'bbc-green': '#18CF48',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
