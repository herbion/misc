var dictionary = [ /* 5 letter words, e.g. crane :) */ ];

// TODO:
// 1. propose a best word with no correct letters
// 2. sort by most information (?)
// 3. fix issue with same letter being green + gray (done, kind of)

let $ = (selector, el=document) => [].slice.call(el.querySelectorAll(selector));
let game = $("body > game-app")[0];

function solve(strategy = "depth") {
	let rows = $("#board game-row", game.shadowRoot);
	let state = rows
		.map(row => $('game-tile', row.shadowRoot))
		.map(word => word.map((letter, index) => {
			return {
			    index: index, 
			    letter: letter.getAttribute("letter"), 
			    evaluation: letter.getAttribute("evaluation")
			}        	
		}))
		.filter(words => words[0].letter);

	let not = fn => arg => !fn(arg);
	let getCategory = (evaluation) => state.map(row => row.filter(letter => letter.evaluation == evaluation)).flat();
	
	let isCorrect = letter => getCategory("correct").map(it => it.letter).includes(letter);
	let isPresent = letter => getCategory("present").map(it => it.letter).includes(letter);
	let isAbsent  = letter =>  getCategory("absent").map(it => it.letter).includes(letter);
	
	let hasCorrect = word => getCategory("correct").every(({letter, index}) => word[index] == letter);
	let hasPresent = word => getCategory("present").every(({letter, index}) => word[index] != letter && word.includes(letter));
	let hasAbsent  = word => getCategory("absent").some(({letter, index})   => word.includes(letter) && !(isCorrect(letter) || isPresent(letter)));

	if (strategy == "depth") {
		return dictionary
		    .filter(hasCorrect)
		    .filter(hasPresent)
		    .filter(not(hasAbsent))
		    .sort();
	} else {
		return dictionary
		    .filter(word => {
				var letters = word.split('');
				return letters.every(not(isCorrect))
					&& letters.every(not(isPresent))
					&& letters.every(not(isAbsent))
			})
		    .sort();
	}
}

function enter(word) {
	if (!word) return;
 	var keyboard = $('game-keyboard', game.shadowRoot)[0].shadowRoot;
	var buttons = $("[data-key]", keyboard);
	var find = letter => buttons.filter(button => button.dataset.key == letter).shift();
	word.split('').forEach(letter => find(letter).click());
	find('↵').click();
}

var options = {
	depth: solve("depth"),
	breadth: solve("breadth")
};

console.log("depth", options.depth.length, options.depth);
console.log("breadth", options.breadth.length, options.breadth);

// too brute
var choice = options.depth.length < options.breadth.length ? "depth" : "breadth";
enter(options[choice][0]);
