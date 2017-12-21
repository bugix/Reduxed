//
//  ViewController.swift
//  Reduxed
//
//  Created by Martin Imobersteg on 21.12.17.
//  Copyright © 2017 Martin Imobersteg. All rights reserved.
//

import UIKit
import ReSwift

struct Question {
    let id: String
    let text: String
}

let questions = [Question(id: "99", text: "Question Text 1 (99)"), Question(id: "11", text: "Question Text 2 (11)"), Question(id: "33", text: "Question Text 3 (33)"), Question(id: "13", text: "Question Text 4 (13)"), Question(id: "42", text: "Question Text 5 (42)")]

let shuffledQuestionIds = questions.map( { (question) -> String in question.id }).shuffled()

struct AppState: StateType {
    let student = "1234567890"
    let sortOrder = shuffledQuestionIds
    var answers = [String: String]()
    var answeredQuestions = 0
    var currentQuestionIndex = 0
    var currentQuestion = questions.first { (question) -> Bool in question.id == shuffledQuestionIds.first }!
    var submitted = false
}

struct NextQuestionAction: Action {}

struct PreviousQuestionAction: Action {}

struct SubmitAction: Action {}

struct AnswerQuestionAction: Action {
    let id: String
    let text: String
}

func appReducer(action: Action, state: AppState?) -> AppState {
    var state = state ?? AppState()

    switch action {
    case let answer as AnswerQuestionAction:

        if answer.text != "" {
            if state.answers.index(forKey: answer.id) == nil {
                state.answeredQuestions = state.answeredQuestions + 1
            }

            state.answers[answer.id] = answer.text
        }
        else {
            state.answers[answer.id] = nil
            state.answeredQuestions = state.answeredQuestions - 1
        }

    case _ as NextQuestionAction:
        if (state.currentQuestionIndex < questions.count - 1) {
            state.currentQuestionIndex = state.currentQuestionIndex + 1
            state.currentQuestion = questions.first { (question) -> Bool in question.id == state.sortOrder[state.currentQuestionIndex] }!
        }
    case _ as PreviousQuestionAction:
        if (state.currentQuestionIndex > 0) {
            state.currentQuestionIndex = state.currentQuestionIndex - 1
            state.currentQuestion = questions.first { (question) -> Bool in question.id == state.sortOrder[state.currentQuestionIndex] }!
        }
    case _ as SubmitAction:
        state.submitted = true
        print(state)
    default:
        break
    }

    return state
}

let loggingMiddleware: Middleware<Any> = { dispatch, getState in
    return { next in
        return { action in
            print(action)
            return next(action)
        }
    }
}

let mainStore = Store<AppState>(
    reducer: appReducer,
    state: nil,
    middleware: [loggingMiddleware]
)

class ViewController: UIViewController, StoreSubscriber, UITextViewDelegate {

    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    @IBOutlet weak var questionIndexLabel: UILabel!
    @IBOutlet weak var questionTextLabel: UILabel!
    
    @IBOutlet weak var answerText: UITextView!

    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var submitButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        answerText.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        mainStore.subscribe(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        mainStore.unsubscribe(self)
    }

    func newState(state: AppState) {

        if state.currentQuestionIndex > 0 {
            previousButton.isEnabled = true
        }
        else {
            previousButton.isEnabled = false
        }

        if state.currentQuestionIndex < questions.count - 1 {
            nextButton.isEnabled = true
        }
        else {
            nextButton.isEnabled = false
        }

        if state.answeredQuestions == questions.count {
            submitButton.isEnabled = true
        }
        else {
            submitButton.isEnabled = false
        }

        if state.submitted {
            answerText.isEditable = false
            previousButton.isEnabled = false
            nextButton.isEnabled = false
            submitButton.isEnabled = false
            let alert = UIAlertController(title: "Thanks", message: "You may go home now", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true, completion: nil)
        }

        questionIndexLabel.text = "\(state.currentQuestionIndex)"
        statusLabel.text = "\(state.answeredQuestions) of \(questions.count) Answered"
        questionIndexLabel.text = "\(state.currentQuestionIndex + 1)"
        questionTextLabel.text = state.currentQuestion.text
        answerText.text = state.answers[state.currentQuestion.id]
    }

    func textViewDidChange(_ textView: UITextView) {
        mainStore.dispatch(AnswerQuestionAction(id: mainStore.state.currentQuestion.id, text: textView.text))
    }

    @IBAction func previousButtonTapped(_ sender: Any) {
        mainStore.dispatch(PreviousQuestionAction())
    }

    @IBAction func nextButtonTapped(_ sender: Any) {
        mainStore.dispatch(NextQuestionAction())
    }

    @IBAction func submitButtonTapped(_ sender: Any) {
        mainStore.dispatch(SubmitAction())
    }

}

extension MutableCollection {
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

