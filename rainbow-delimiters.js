console.log("Loading scribble-rainbow-delimiters...");
console.log("jQuery-" + jQuery().jquery);

// const colors = [
//   "darkred",
//   "#b16286",
//   "IndianRed",
//   "#7e5e60",
//   "#FF1493"
// ]

const colors = [
  "DarkRed",
  "firebrick",
  "IndianRed",
  "LightCoral",
  "Salmon",
  "DarkSalmon",
  "LightSalmon"
]


// file:///Applications/Racket%20v8.0/doc/scribble/builtin-css.html?q=elem
const RDBlocks = [
  ".SCodeFlow",
  "blockquote.SVInsetFlow"
]


function getRandomStr() {
  return Math.floor(Math.random() * 10000).toString();
}
function hex(x) {
  return ("0" + parseInt(x).toString(16)).slice(-2);
}
function rgb2hex(str) {
  rgb = str.match(/^rgb\((\d+),\s*(\d+),\s*(\d+)\)$/);
  if (rgb === null) {
    return str;
  } else {
    return "#" + hex(rgb[1]) + hex(rgb[2]) + hex(rgb[3]);
  }
}


function colorizing(RDBlock) {
  $(RDBlock).each(function(i) {
    if (this.classList.contains("rd-colorized")) { return false; }
    if ($(this).find("span.rd-bracket").length) { return false; }
    if (this.innerHTML.match(/(\(|\)|\[|\]|\{|\})/)) { debugger; }
    $(this).find("span").each(function(i) {
        if (this.innerText.match(/(\(|\)|\[|\]|\{|\})/g)) {
          this.innerHTML = this.innerHTML.replace(/(\(|\)|\[|\]|\{|\})/g, function(str) {
            return `<span class='rd-bracket'>${str}</span>`;
          });
        }
      });

    $(this).addClass("rd-colorized");
  })

  var recordDepth = 0;
  var randomId;
  var randomIdds = [];
  $(RDBlock).find("span.rd-bracket").each(function(i) {
    if (this.className.includes("rd-id-")) { return false; }
    if (recordDepth == 0) { randomId = getRandomStr(); }

    if (["(", "[", "{"].includes(this.textContent)) {
      let color;
      if ($(this).parent()[0].className === "RktVal") {
        color = "#228b22";
      } else if ($(this).parent()[0].className === "RktRes") {
        color = "#0000af";
      } else if ($(this).parent()[0].className === "RktOpt") {
        color = "black";
      } else if ($(this).parent()[0].className === "RktErr") {
        color = "red";
      } else {
        color = colors[recordDepth % colors.length];
      };

      var idd = getRandomStr(); randomIdds.push(idd);
      $(this).css("color", color);
      this.classList.add(`rd-id-${randomId}`);
      this.classList.add(`rd-idd-${idd}`);
      this.classList.add(`rd-depth-${recordDepth}`);
      // this.title = `rd-bk-id/depth:  ${randomId}/${recordDepth}`
      recordDepth++;
      // $(this).css("font-weight", "bolder");
    }

    if ([")", "]", "}"].includes(this.textContent)) {
      recordDepth--;

      let color;
      if ($(this).parent()[0].className === "RktVal") {
        color = "#228b22";
      } else if ($(this).parent()[0].className === "RktRes") {
        color = "#0000af";
      } else if ($(this).parent()[0].className === "RktErr") {
        color = "red";
      } else {
        color = colors[recordDepth % colors.length];
      };

      var idd = randomIdds.pop();
      $(this).css("color", color);
      this.classList.add(`rd-id-${randomId}`);
      this.classList.add(`rd-idd-${idd}`);
      this.classList.add(`rd-depth-${recordDepth}`);
      // this.title = `rd-bk-id/depth:  ${randomId}/${recordDepth}`
    }
  });
}

function findClosestElms(elm) {
  var matchingStr = elm.textContent;
  var matchingArr;
  switch(matchingStr) {
  case '(':
  case ')':
    matchingArr = ['(', ')'];
    break;
  case '[':
  case ']':
    matchingArr = ['[', ']'];
    break;
  case '{':
  case '}':
    matchingArr = ['{', '}'];
    break;
  }

  var classNames = elm.className.split(" ");
  var rdDepth = classNames.find(function(e) { return e.startsWith("rd-depth-") });
  var depthNum = rdDepth.split("-").pop();
  var rdId = classNames.find(function(e) { return e.startsWith("rd-id-") });
  var rdIdd = classNames.find(function(e) { return e.startsWith("rd-idd-") });
  var parentElm = elm.closest(".rd-colorized").parentElement;
  var cousinElms = $(parentElm).find(`span.${rdDepth}.${rdId}`).not(`span.${rdIdd}`).filter(function(ii) {
    return matchingArr.includes(this.textContent);
  });
  var brotherElms = $(parentElm).find(`span.${rdDepth}.${rdId}.${rdIdd}`).filter(function(ii) {
    return matchingArr.includes(this.textContent);
  });
  return [ brotherElms, cousinElms ];
}

/////// actions /////////
handler = function main() {
  RDBlocks.forEach(function(e) {
    if ($(e).length) { colorizing(e); }
  });

  $("span.rd-bracket").mouseover(function(i) {
    console.log(this.classList);
    var color = rgb2hex(this.style.color);
    if (color == "white") { return false };
    if (!color.length) { return console.log(`mouseover on an unexpected rd-bracket element: ${this.outerHTML}`); }
    [ brotherElms, cousinElms ] = findClosestElms(this);
    brotherElms.css("color", "white");
    brotherElms.css("background", color);
    cousinElms.css("background", "#E0E0E0");  // whitesmoke gainsboro
  });

  $("span.rd-bracket").mouseleave(function(i) {
    var color = rgb2hex(this.style.backgroundColor);
    if (color == "transparent") { return false };
    if (!color.length) { return console.log(`mouseleave on an unexpected rd-bracket element: ${this.outerHTML}`); }
    [ brotherElms, cousinElms ] = findClosestElms(this);
    brotherElms.css("color", color);
    brotherElms.css("background", "transparent");
    cousinElms.css("background", "transparent");
  });
}

$(document).ready(function() { $( handler ); });
