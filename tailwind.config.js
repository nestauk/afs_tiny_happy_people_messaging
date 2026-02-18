const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/frontend/**/*.{js,ts,vue}',
    './app/views/**/*.{erb,haml,html,slim}',
  ],
  theme: {
    extend: {
      colors: {
        'bbc-blue': '#1079EB',
        'bbc-dark-blue': '#025fc9',
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
      },
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      }
    }
  }
}
