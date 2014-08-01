$(document).ready(function(){
  player_hits();
  player_stays();
});

function player_hits(){
  $(document).on('click','form#hit_form input',function(){
    $.ajax({
      type: 'POST',
      url: '/player_hit'
    }).done(function(mgs){
      $('#game').replaceWith(mgs);
    });
    return false;
  });
}


function player_stays(){
  $(document).on('click','form#stay_form input',function(){
    $.ajax({
      type: 'POST',
      url: '/player_stay'
    }).done(function(mgs){
      $('#game').replaceWith(mgs);
    });
    return false;
  });
}