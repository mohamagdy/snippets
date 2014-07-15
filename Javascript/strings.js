// This will add a function named "titleize" to the JavaScript strings
String.prototype.titleize = function () {
  var words = this.replaceAll(/[^A-Za-z0-9]/, ' ').split(' ');
  var titleize = '';

  for (word in words)
    titleize += words[word].charAt(0).toUpperCase() + words[word].slice(1);

  return titleize;
}

// This method capitalize a given string and remove all non alphanumeric characters
String.prototype.capitalize = function () {
  var words = this.replaceAll(/[^A-Za-z0-9]/, ' ').split(' ');
  var capitalized = words[0].charAt(0).toUpperCase() + words[0].slice(1);
  words.splice(0, 1);
  capitalized += ' ' + words.join(' ');

  return capitalized;
}

// Replace all occurrence of a value in a string
String.prototype.replaceAll = function (target, replacement) {
  return this.split(target).join(replacement);
};