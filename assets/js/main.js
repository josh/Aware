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

  var clock = document.querySelector('.js-clock');
  function updateClock() {
    var now = new Date();
    var day = now.toUTCString().split(",")[0];
    var hour = (now.getHours() % 12);
    var min = ("0" + now.getMinutes()).slice(-2);
    var meridian = now.getHours() > 12 ? "PM" : "AM";
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

(function() {
  window.GoogleAnalyticsObject = 'ga';
  window.ga = function ga() {
    ga.q.push(arguments);
  };
  ga.q = [];
  ga.l = (new Date()).getTime();

  ga('create', 'UA-74056549-2', 'auto');
  ga('send', 'pageview');
})();
