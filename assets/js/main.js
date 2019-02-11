(function() {
  // Clicking menubar toggles "dark menu bar"
  document.querySelector('.js-toggle-dark-menubar').addEventListener('click', function() {
    this.classList.toggle('menubar-dark');
  });

  var timer = document.querySelector('.js-aware-timer');
  var pageLoad = new Date() - (Math.random() * 1000 * 60 * 30);
  function updateTimer() {
    var now = new Date();
    var min = Math.floor((now - pageLoad) / (1000 * 60));
    var text = min + "m";

    timer.textContent = text;
  }

  var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  var clock = document.querySelector('.js-clock');
  function updateClock() {
    var now = new Date();
    var day = days[now.getDay()];
    var hour = (now.getHours() + 11) % 12 + 1;
    var min = ("0" + now.getMinutes()).slice(-2);
    var meridian = now.getHours() >= 12 ? "PM" : "AM";
    var text = day + " " + hour + ":" + min + " " + meridian;

    clock.textContent = text;
  }

  setInterval(function() {
    updateTimer();
    updateClock();
  }, 30000);

  updateTimer();
  updateClock();
})();
