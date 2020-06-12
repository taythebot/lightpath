function delay_eval(min, max) {
	return (Math.random() * (max - min) + min) * 1000;
}

if (navigator.cookieEnabled && document.cookie.indexOf('{{challenge_name}}') == -1) {
	setTimeout(function() {
		location.reload();
	}, delay_eval({{delay_min}}, {{delay_max}}));
} else {
	document.write("<h3 align='center' style='color:red'>Please enable cookies and reload the page</h3>");
}