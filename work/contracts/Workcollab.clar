;; Work Collaboration Contract
;; This contract manages tasks, contributors, and payments for collaborative work projects

(define-data-var contract-owner principal tx-sender)
(define-data-var project-name (string-ascii 50) "")
(define-data-var project-description (string-ascii 500) "")
(define-data-var project-deadline uint u0)
(define-data-var project-budget uint u0)
(define-data-var project-status (string-ascii 20) "not-started") ;; not-started, in-progress, completed

;; Task structure: id, name, description, status, deadline, reward
(define-map tasks 
  { task-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    status: (string-ascii 20),
    deadline: uint,
    reward: uint,
    assigned-to: (optional principal)
  }
)

;; Contributors map: address to role and reputation
(define-map contributors
  { address: principal }
  {
    role: (string-ascii 50),
    reputation: uint,
    tasks-completed: uint,
    earnings: uint
  }
)

;; Task submissions
(define-map task-submissions
  { task-id: uint, submitter: principal }
  {
    submission-url: (string-ascii 255),
    timestamp: uint,
    status: (string-ascii 20) ;; pending, approved, rejected
  }
)

;; Helper validation function for numeric inputs
(define-private (validate-numeric-input (value uint) (min-value uint) (max-value uint))
  (and (>= value min-value) (<= value max-value))
)

;; Helper validation function for string inputs
(define-private (validate-string-input (value (string-ascii 500)) (min-length uint) (max-length uint))
  (and (>= (len value) min-length) (<= (len value) max-length))
)

;; Initialize the project
(define-public (initialize-project (name (string-ascii 50)) (description (string-ascii 500)) (deadline uint) (budget uint))
  (begin
    ;; Validate caller is contract owner
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    ;; Validate project is not already started
    (asserts! (is-eq (var-get project-status) "not-started") (err u400))
    
    ;; Validate inputs
    (asserts! (validate-string-input name u1 u50) (err u420))
    (asserts! (validate-string-input description u1 u500) (err u421))
    (asserts! (> deadline block-height) (err u401))
    (asserts! (> budget u0) (err u402))
    
    ;; Create validated copies of inputs
    (let 
      (
        (validated-name name)
        (validated-description description)
        (validated-deadline deadline)
        (validated-budget budget)
      )
      ;; Set project details with validated data
      (var-set project-name validated-name)
      (var-set project-description validated-description)
      (var-set project-deadline validated-deadline)
      (var-set project-budget validated-budget)
      (var-set project-status "in-progress")
      (ok true)
    )
  )
)

;; Create a new task
(define-public (create-task (task-id uint) (name (string-ascii 100)) (description (string-ascii 500)) (deadline uint) (reward uint))
  (begin
    ;; Validate caller is contract owner
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    ;; Validate project is in progress
    (asserts! (is-eq (var-get project-status) "in-progress") (err u400))
    ;; Validate task ID is not already used
    (asserts! (is-none (map-get? tasks {task-id: task-id})) (err u409))
    
    ;; Validate inputs
    (asserts! (validate-string-input name u1 u100) (err u422))
    (asserts! (validate-string-input description u1 u500) (err u423))
    (asserts! (<= deadline (var-get project-deadline)) (err u410))
    (asserts! (> deadline block-height) (err u424))
    (asserts! (and (> reward u0) (<= reward (var-get project-budget))) (err u411))
    
    ;; Create validated copies of inputs
    (let 
      (
        (validated-id task-id)
        (validated-name name)
        (validated-description description)
        (validated-deadline deadline)
        (validated-reward reward)
      )
      ;; Create task after validation
      (map-set tasks 
        {task-id: validated-id}
        {
          name: validated-name,
          description: validated-description,
          status: "open",
          deadline: validated-deadline,
          reward: validated-reward,
          assigned-to: none
        }
      )
      (ok true)
    )
  )
)

;; Register as a contributor
(define-public (register-contributor (role (string-ascii 50)))
  (begin
    ;; Validate contributor is not already registered
    (asserts! (is-none (map-get? contributors {address: tx-sender})) (err u409))
    ;; Validate role is not empty
    (asserts! (> (len role) u0) (err u412))
    ;; Validate project is in progress
    (asserts! (is-eq (var-get project-status) "in-progress") (err u400))
    
    ;; Register contributor after validation
    (map-set contributors
      {address: tx-sender}
      {
        role: role,
        reputation: u0,
        tasks-completed: u0,
        earnings: u0
      }
    )
    (ok true)
  )
)

;; Assign a task to a contributor
(define-public (assign-task (task-id uint) (contributor principal))
  (let (
    (task (unwrap! (map-get? tasks {task-id: task-id}) (err u404)))
    (contributor-data (unwrap! (map-get? contributors {address: contributor}) (err u404)))
  )
    ;; Validate caller is contract owner
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    ;; Validate task status is open
    (asserts! (is-eq (get status task) "open") (err u400))
    ;; Validate project is in progress
    (asserts! (is-eq (var-get project-status) "in-progress") (err u400))
    ;; Validate task deadline hasn't passed
    (asserts! (> (get deadline task) block-height) (err u413))
    
    ;; Create validated copy of task ID
    (let ((validated-id task-id))
      ;; Assign task after validation
      (map-set tasks
        {task-id: validated-id}
        (merge task {status: "assigned", assigned-to: (some contributor)})
      )
      (ok true)
    )
  )
)

;; Submit work for a task
(define-public (submit-task (task-id uint) (submission-url (string-ascii 255)))
  (let ((task (unwrap! (map-get? tasks {task-id: task-id}) (err u404))))
    ;; Validate task is assigned
    (asserts! (is-some (get assigned-to task)) (err u400))
    ;; Validate caller is the assigned contributor
    (asserts! (is-eq (some tx-sender) (get assigned-to task)) (err u403))
    ;; Validate task status is assigned
    (asserts! (is-eq (get status task) "assigned") (err u400))
    ;; Validate submission URL
    (asserts! (validate-string-input submission-url u1 u255) (err u414))
    ;; Validate project is in progress
    (asserts! (is-eq (var-get project-status) "in-progress") (err u400))
    ;; Validate task deadline hasn't passed
    (asserts! (>= (get deadline task) block-height) (err u415))
    
    ;; Create validated copies of inputs
    (let (
      (validated-id task-id)
      (validated-url submission-url)
    )
      ;; Record submission after validation
      (map-set task-submissions
        {task-id: validated-id, submitter: tx-sender}
        {
          submission-url: validated-url,
          timestamp: block-height,
          status: "pending"
        }
      )
      
      ;; Update task status
      (map-set tasks
        {task-id: validated-id}
        (merge task {status: "submitted"})
      )
      (ok true)
    )
  )
)

;; Approve a task submission and release payment
(define-public (approve-submission (task-id uint) (submitter principal))
  (let (
    (task (unwrap! (map-get? tasks {task-id: task-id}) (err u404)))
    (submission (unwrap! (map-get? task-submissions {task-id: task-id, submitter: submitter}) (err u404)))
    (contributor-data (unwrap! (map-get? contributors {address: submitter}) (err u404)))
  )
    ;; Validate caller is contract owner
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u403))
    ;; Validate task status is submitted
    (asserts! (is-eq (get status task) "submitted") (err u400))
    ;; Validate submission status is pending
    (asserts! (is-eq (get status submission) "pending") (err u400))
    ;; Validate project is in progress
    (asserts! (is-eq (var-get project-status) "in-progress") (err u400))
    ;; Validate the submitter is the assigned contributor
    (asserts! (is-eq (some submitter) (get assigned-to task)) (err u416))
    
    ;; Create validated copies of inputs
    (let (
      (validated-id task-id)
      (validated-submitter submitter)
    )
      ;; Update task status
      (map-set tasks
        {task-id: validated-id}
        (merge task {status: "completed"})
      )
      
      ;; Update submission status
      (map-set task-submissions
        {task-id: validated-id, submitter: validated-submitter}
        (merge submission {status: "approved"})
      )
      
      ;; Update contributor reputation and earnings
      (map-set contributors
        {address: validated-submitter}
        {
          role: (get role contributor-data),
          reputation: (+ (get reputation contributor-data) u1),
          tasks-completed: (+ (get tasks-completed contributor-data) u1),
          earnings: (+ (get earnings contributor-data) (get reward task))
        }
      )
      
      ;; Send payment to the contributor
      (let ((payment-result (as-contract (stx-transfer? (get reward task) contract-caller validated-submitter))))
        (asserts! (is-ok payment-result) (err u417))
        (ok true)
      )
    )
  )
)