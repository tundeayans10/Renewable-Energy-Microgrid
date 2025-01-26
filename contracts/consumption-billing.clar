;; Consumption Billing Contract

(define-data-var next-consumer-id uint u0)

(define-map consumers
  { consumer-id: uint }
  {
    owner: principal,
    total-consumed: uint,
    balance: uint
  }
)

(define-map energy-consumption
  { consumer-id: uint, timestamp: uint }
  { amount: uint }
)

(define-constant energy-price u100) ;; Price per unit of energy (in microstacks)

(define-public (register-consumer)
  (let
    ((new-id (var-get next-consumer-id))
     (owner tx-sender))
    (map-set consumers
      { consumer-id: new-id }
      {
        owner: owner,
        total-consumed: u0,
        balance: u0
      }
    )
    (var-set next-consumer-id (+ new-id u1))
    (ok new-id)
  )
)

(define-public (record-consumption (consumer-id uint) (amount uint))
  (let
    ((owner tx-sender)
     (timestamp block-height)
     (cost (* amount energy-price)))
    (match (map-get? consumers { consumer-id: consumer-id })
      consumer (begin
        (asserts! (is-eq owner (get owner consumer)) (err u403))
        (map-set energy-consumption
          { consumer-id: consumer-id, timestamp: timestamp }
          { amount: amount }
        )
        (map-set consumers
          { consumer-id: consumer-id }
          (merge consumer {
            total-consumed: (+ (get total-consumed consumer) amount),
            balance: (+ (get balance consumer) cost)
          })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

(define-public (pay-bill (consumer-id uint) (payment uint))
  (let
    ((owner tx-sender))
    (match (map-get? consumers { consumer-id: consumer-id })
      consumer (begin
        (asserts! (is-eq owner (get owner consumer)) (err u403))
        (asserts! (>= payment (get balance consumer)) (err u400))
        (try! (stx-transfer? payment tx-sender (as-contract tx-sender)))
        (map-set consumers
          { consumer-id: consumer-id }
          (merge consumer { balance: (- (get balance consumer) payment) })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

(define-read-only (get-consumer (consumer-id uint))
  (map-get? consumers { consumer-id: consumer-id })
)

(define-read-only (get-consumption (consumer-id uint) (timestamp uint))
  (map-get? energy-consumption { consumer-id: consumer-id, timestamp: timestamp })
)

