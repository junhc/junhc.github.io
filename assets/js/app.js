---
---
(function($,window){
  $(function(){
    var jf = new Firebase($CONFIG["firebase"]);
  
    jf.child("pv").on("value", function(data){
  	var pv = data.val();
  	var $pv = $("#pv");
  	if($pv.size() > 0 && pv > 1){
  		$pv.html(pv);
  	}
    });
  
    jf.child("details/" + $CONFIG['page']).on("value", function(data){
  	var sp = data.val();
  	var $sp = $("#sp");
  	if($sp.size() >0 && sp > 1){
  		$sp.html(sp);
  	}
    });
  
    jf.child("pv").transaction(function(pv){
  	return (pv || 0) + 1;
    });
  
    jf.child("details/" + $CONFIG["page"]).transaction(function(sp){
  	return (sp || 0) + 1;
    });
  
  });
  // 等待网页中所有元素都完全加载到浏览器之后再执行.
  window.onload = function(){
    $('#container').masonry({
  	itemSelector: '.item',
  	columnWidth: 5,
  	isAnimated: true
    });
  };
})(jQuery,window);
