;; Energy Production Tracking Contract

(define-data-var next-producer-id uint u0)

(define-map producers
  { producer-id: uint }
  {
    owner: principal,
    energy-type: (string-ascii 20),
    capacity: uint,
    total-produced: uint
  }
)

(define-map energy-production
  { producer-id: uint, timestamp: uint }
  { amount: uint }
)

(define-public (register-producer (energy-type (string-ascii 20)) (capacity uint))
  (let
    ((new-id (var-get next-producer-id))
     (owner tx-sender))
    (map-set producers
      { producer-id: new-id }
      {
        owner: owner,
        energy-type: energy-type,
        capacity: capacity,
        total-produced: u0
      }
    )
    (var-set next-producer-id (+ new-id u1))
    (ok new-id)
  )
)

(define-public (record-production (producer-id uint) (amount uint))
  (let
    ((owner tx-sender)
     (timestamp block-height))
    (match (map-get? producers { producer-id: producer-id })
      producer (begin
        (asserts! (is-eq owner (get owner producer)) (err u403))
        (map-set energy-production
          { producer-id: producer-id, timestamp: timestamp }
          { amount: amount }
        )
        (map-set producers
          { producer-id: producer-id }
          (merge producer { total-produced: (+ (get total-produced producer) amount) })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

(define-read-only (get-producer (producer-id uint))
  (map-get? producers { producer-id: producer-id })
)

(define-read-only (get-production (producer-id uint) (timestamp uint))
  (map-get? energy-production { producer-id: producer-id, timestamp: timestamp })
)

