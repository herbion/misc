var dictionary = [ /* 5 letter words, e.g. crane :) */ ];

let $ = (selector, el = document) => [].slice.call(el.querySelectorAll(selector));
let game = $("body > game-app")[0];
let rows = $("#board game-row", game.shadowRoot);

var state = rows
        .map(row => $('game-tile', row.shadowRoot))
        .map(word => word.map((letter, index) => {
	        return {
	            index: index, 
	            letter: letter.getAttribute("letter"), 
	            evaluation: letter.getAttribute("evaluation")
	        }        	
        }))
	.filter(words => words[0].letter)
;


let not = fn => arg => !fn(arg);
let getCategory = (evaluation) => state.map(row => row.filter(letter => letter.evaluation == evaluation)).flat();

let isCorrect = letter => getCategory("correct").map(it => it.letter).includes(letter);

let hasCorrect = word => getCategory("correct").every(({letter, index}) => word[index] == letter);
let hasPresent = word => getCategory("present").every(({letter, index}) => word[index] != letter && word.includes(letter));
let hasAbsent  = word => getCategory("absent").some(({letter, index})   => word.includes(letter) && !isCorrect(letter));

let match = dictionary
    .filter(hasCorrect)
    .filter(hasPresent)
    .filter(not(hasAbsent))
    .sort();

console.log(match);

// TODO:
// 1. propose a best word with no correct letters
// 2. sort by most information (?)
// 3. fix issue with same letter being green + gray (done, kind of)
