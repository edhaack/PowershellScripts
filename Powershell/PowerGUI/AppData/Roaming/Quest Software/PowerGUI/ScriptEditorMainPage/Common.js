//////////////////////////////////////////////////////////////////////////////////////////////////////////
// System extensions
String.prototype.trim = function () {
	return this.replace(/^\s*/, "").replace(/\s*$/, "");
};

String.prototype.removeQuotes = function () {
	if (this.length > 1 && this.charAt(0) == "\"" && this.charAt(this.length - 1) == "\"") {
		return this.substr(1, this.length - 2);
	}

	return this;
};

String.prototype.endsWithI = function (str) {
	if (this != null) {
		if (this.length >= str.length) {
			return this.substr(this.length - str.length).toLowerCase() == str.toLowerCase();
		}
	}

	return false;
}

String.prototype.startsWithI = function (str) {
	if (this != null) {
		if (this.length >= str.length) {
			return this.substr(0, str.length).toLowerCase() == str.toLowerCase();
		}
	}

	return false;
}

// Recursive search
function findChildByClass(node, name) {
	var child = node.firstChild
	while (child != null) {
		if (child.className == name) {
			return child;
		}

		var res = findChildByClass(child, name);
		if (res != null) {
			return res;
		}

		child = child.nextSibling;
	}
}

function getElementsByClassName(classname, node)
{
	if(!node) node = document.getElementsByTagName("body")
    var a = [];
    var re = new RegExp('\\b' + classname + '\\b');
    var els = document.getElementsByTagName("*");
    for(var i=0,j=els.length; i<j; i++)
        if(re.test(els[i].className))a.push(els[i]);
    return a;
}

function anchorLinks(text) {
	var reg = new RegExp("http://[\\S]+", "i");
	var strNew = "";

	while ((found = reg.exec(text)) != null) {
		strNew += text.substr(0, found.index) + "<a href=\"" + found[0] + "\" target=\"_blank\">" + found[0] + "</a>";
		text = text.substr(found.lastIndex);
	}

	return strNew;
}

function getXMLHttpRequest() 
{
    if (window.XMLHttpRequest) {
        return new window.XMLHttpRequest;
    }
    else {
        try {
            return new ActiveXObject("MSXML2.XMLHTTP.3.0");
        }
        catch(ex) {
            return null;
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
var g_CfgProp_WelcomePageRefreshPeriod = "WelcomePageRefreshPeriod";
var g_CfgProp_WelcomePageElementCount = "WelcomePageElementCount";
var g_CfgProp_IsAllowedNetworkConnection = "IsAllowedNetworkConnection";
var g_CfgProp_PageUpdateAllowed = "WelcomePageUpdateContent";

var g_UpdateTimerInterval = 600000;
var g_MaxItemsInList = 5;
var g_MaxItemsInDiscussionsList = 5;
var g_UpdateAllowed = true;
var g_NetworkAllowed = true;

function emptyFunction() {
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// Single request object
function DataRequest() {
	this._Request = new ActiveXObject("Microsoft.XMLDOM");
	this.Completed = null;

	var _This = this;
	this._Request.onreadystatechange = function () {
		if (_This._Request != null && _This._Request.readyState == 4) {
			if (_This.Completed != null) {
				_This.Completed(_This._Request.documentElement);
			}

			_This.Completed = emptyFunction;
			_This._Request = null;
			_This = null;
		}
	}
}

DataRequest.prototype.Load = function (url) {
	this._Request.load(url);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////

var g_arrDataHandlers = new Array();

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function DataHandler(id, getter, setter, urls, updater) {
	this._Requests = new Array();

	this.UpdateOnline = function () {
		if (urls != null) {
			if (!g_UpdateAllowed) {
				return;
			}

			if (typeof (urls) == "string") {
				var s = urls;
				urls = [s];
			}

			for (var i = 0; i < urls.length; i++) {
				var idRequest = id + urls[i];

				if (this._Requests[idRequest] == null) {
					this._Requests[idRequest] = new DataRequest();

					var _This = this;
					this._Requests[idRequest].Completed = function (xmlDoc) {
						_This._Requests[idRequest] = null;
						if (xmlDoc != null) {
							var retval = updater(xmlDoc);
							if (retval != null && getter() != retval) {
								setter(retval);
								updatePersistentDataStorage(id, retval);
							}
						}
					}

					this._Requests[idRequest].Load(urls[i]);
				}
			}
		}
		else {
			var retval = updater();
			if (retval != null && getter() != retval) {
				setter(retval);
				updatePersistentDataStorage(id, retval);
			}
		}
	}

	setter(getPersistentData(id));
}

function GenericDataHandler(id, getter, setter, urls, updater) {
	g_arrDataHandlers[id] = new DataHandler(id, getter, setter, urls, updater);
}

function SimpleDivDataHandler(id, divid, urls, updater) {
	GenericDataHandler(id,
		function () { return document.getElementById(divid).innerHTML; },
		function (value) { document.getElementById(divid).innerHTML = value; },
		urls, updater);
}

function SimpleDivStaticDataHandler(id, divid, updater) {
	SimpleDivDataHandler(id, divid, null, updater);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function updatePersistentDataStorage(id, value) {
	if (window.external != null) {
		try {
			window.external.Put(id, value);
		}
		catch (e) {
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function getPersistentData(id) {
	if (window.external != null) {
		try {
			var val = window.external.Get(id);
			if (val != null && val != "") {
				return val;
			}
		}
		catch (e) {
		}
	}

	return "loading...";
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function getConfigurationSetting(id) {
	if (window.external != null) {
		try {
			return window.external.Get(id);
		}
		catch (e) {
		}
	}

	return null;
}

function getConfigurationSettingAsArray(id) {
	var val = getConfigurationSetting(id);
	if (val != null && val != "") {
		var arr = val.split(",");
		for (k in arr) {
			arr[k] = arr[k].removeQuotes();
		}

		return arr;
	}

	return new Array();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////

function onTimer() {
	for (key in g_arrDataHandlers) {
		g_arrDataHandlers[key].UpdateOnline();
	}
}

function onTimerFirst() {
	onTimer();
	setInterval(onTimer, g_UpdateTimerInterval);
}

function readConfiguration() {
	var val = getConfigurationSetting(g_CfgProp_WelcomePageRefreshPeriod);
	if (val != null) {
		g_UpdateTimerInterval = parseInt(val) * 60000;
		if (g_UpdateTimerInterval < 300000) { // 5 minutes
			g_UpdateTimerInterval = 300000;
		}
	}

	val = getConfigurationSetting(g_CfgProp_WelcomePageElementCount);
	if (val != null) {
		g_MaxItemsInDiscussionsList = parseInt(val);
		if (g_MaxItemsInDiscussionsList < 5) {
			g_MaxItemsInDiscussionsList = 5;
		}
	}

	val = getConfigurationSetting(g_CfgProp_PageUpdateAllowed);
	if (val != null) {
		g_UpdateAllowed = val.toLowerCase() != "false";
	}

	val = getConfigurationSetting(g_CfgProp_IsAllowedNetworkConnection);
	if (val != null) {
		g_NetworkAllowed = val.toLowerCase() != "false";
	}

	if (!g_NetworkAllowed) {
		g_UpdateAllowed = false;
	}
}

function onLoadHandler() {
	readConfiguration();

	onResizeHandler();

	initAllDataHandlers();

	var blocks = getElementsByClassName("BlockCollapser")
	for (i in blocks) {
		addToggleCollapseHandler(blocks[i]);

		if (getPersistentData("CollapsableBlock_" + blocks[i].id) != "collapsed" && blocks[i].id != "VideoCollapser") {
			blocks[i].fireEvent("onmousedown", document.createEventObject());
		}
	}

	setTimeout(onTimerFirst, 5000);
}

function addToggleCollapseHandler(obj) {
	var prevMouseDownEvent = obj.onmousedown;
	if (prevMouseDownEvent != null) {
		obj.onmousedown = function () { prevMouseDownEvent(); toggleCollapse(this); };
	}
	else {
		obj.onmousedown = function () { toggleCollapse(this); };
	}
}

function toggleCollapse(obj) {
	toggleBackgroundImage(obj);

	var dataId = "CollapsableBlock_" + obj.id;

	while ((obj = obj.nextSibling) != null) {
		if (obj.currentStyle.display == 'none') {
			obj.style.display = 'block';
			updatePersistentDataStorage(dataId, "expanded");
		} else {
			obj.style.display = 'none';
			updatePersistentDataStorage(dataId, "collapsed");
		}
	}

	onResizeHandler();
}

//////////////////////////////////////////////////////////////////////////////////////////////
// Replaces TaskPad button image and text when mouse cursor is over the button + revert the image and text back
function onButtonHoverChanged(obj) {
	if (toggleBackgroundImage(obj)) {
		obj.style.fontWeight = 'bold';
	}
	else {
		obj.style.fontWeight = 'normal';
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////
// Changes background image file from XXXX to _XXXX or back
function toggleBackgroundImage(obj) {
	var index = obj.currentStyle.backgroundImage.lastIndexOf("/");
	if (index >= 0) {
		index++;
	}
	else {
		index = 4;
		if (obj.currentStyle.backgroundImage.substr(index, 4) == "\'") {
			index++;
		}
	}

	if (obj.currentStyle.backgroundImage.substr(index, 1) == "_") {
		obj.style.backgroundImage = obj.currentStyle.backgroundImage.substr(0, index) + obj.currentStyle.backgroundImage.substr(index + 1);
		return false;
	}
	else {
		obj.style.backgroundImage = obj.currentStyle.backgroundImage.substr(0, index) + "_" + obj.currentStyle.backgroundImage.substr(index);
		return true;
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////
function strip(html) {
	var tmp = document.createElement("DIV");
	tmp.innerHTML = html;
	return tmp.textContent || tmp.innerText;
}

function DiscussionItem(node) {
	this.IsValid = true;

	var val = node.selectSingleNode("title");
	if (val != null) {
		this.Title = strip(val.text).trim();
	}
	else {
		this.IsValid = false;
	}

	val = node.selectSingleNode("link");
	if (val != null) {
		this.Url = val.text;
	}
	else {
		this.IsValid = false;
	}

	val = node.selectSingleNode("pubDate");
	if (val != null) {
		this.PubDate = new Date(val.text.trim());
	}
	else {
		this.IsValid = false;
	}

	val = node.selectSingleNode("description");
	if (val != null) {
		this.Description = strip(val.text).trim();
	}
}

function AggregatedFeed(maxItems) {
	this._Content = new Array();

	this.Add = function (item) {
		var i = 0;
		for (i = 0; i < this._Content.length; i++) {
			if (item.PubDate >= this._Content[i].PubDate) {
				if (item.Url != this._Content[i].Url) {
					this._Content.splice(i, 0, item);
				}
				break;
			}
		}

		if (i >= this._Content.length) { // Item not inserted
			if (this._Content.length >= maxItems) {
				return false;
			}

			this._Content.push(item); // Add to end
		}
		else {
			// cut array if needed
			if (this._Content.length > maxItems) {
				this._Content.pop();
			}
		}

		return true;
	}

	this.GenerateHTML = function () {
		var strDiscussions = "";
		for (var i = 0; i < this._Content.length; i++) {
			var item = this._Content[i];
			strDiscussions += "<div class=\"ListItem\"><div class=\"ListItemTitle\"><a class=\"ListItemTitle\" target=\"_blank\" href=\"" + item.Url + "\">" + item.Title + "</a></div>";
			if (item.Description != null) {
				strDiscussions += "<div class=\"ListItemDescription\">" + item.Description + "</div><div class=\"ListItemDate\">&nbsp;&nbsp;&nbsp;[" + item.PubDate.toLocaleString() + "]</div>"
			}

			strDiscussions += "</div>"
		}

		return strDiscussions;
	}
}

function initDiscussionFeedHandler(id, url, obj) {
	var aggrFeed = new AggregatedFeed(g_MaxItemsInDiscussionsList);

	GenericDataHandler(id,
							function () { return obj.innerHTML; },
							function (value) { obj.innerHTML = value; },
							url,
							function (xmlDoc) {
								var nodes = xmlDoc.selectNodes("//rss/channel/item");
								if (nodes != null) {
									for (var i = 0; i < nodes.length; i++) {
										var item = new DiscussionItem(nodes[i])
										if (item.IsValid) {
											if (!aggrFeed.Add(item)) {
												break;
											}
										}
									}

									return aggrFeed.GenerateHTML();
								}
							});
}

window.onresize = onResizeHandler;
window.onload = onLoadHandler;
