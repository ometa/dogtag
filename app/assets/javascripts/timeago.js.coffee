# http://timeago.yarp.com/

$(".races.registrations").ready ->
  jQuery.timeago.settings.allowFuture = true
  alert("do")
  $("time.timeago").timeago
