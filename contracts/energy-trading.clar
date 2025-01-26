;; Energy Trading Contract

(define-map energy-offers
  { offer-id: uint }
  {
    seller: principal,
    amount: uint,
    price: uint,
    expiration: uint
  }
)

(define-data-var next-offer-id uint u0)

(define-public (create-offer (amount uint) (price uint) (expiration uint))
  (let
    ((new-id (var-get next-offer-id))
     (seller tx-sender))
    (map-set energy-offers
      { offer-id: new-id }
      {
        seller: seller,
        amount: amount,
        price: price,
        expiration: expiration
      }
    )
    (var-set next-offer-id (+ new-id u1))
    (ok new-id)
  )
)

(define-public (accept-offer (offer-id uint))
  (let
    ((buyer tx-sender))
    (match (map-get? energy-offers { offer-id: offer-id })
      offer (begin
        (asserts! (< block-height (get expiration offer)) (err u400))
        (asserts! (not (is-eq buyer (get seller offer))) (err u403))
        (try! (stx-transfer? (get price offer) buyer (get seller offer)))
        (map-delete energy-offers { offer-id: offer-id })
        (ok true)
      )
      (err u404)
    )
  )
)

(define-public (cancel-offer (offer-id uint))
  (let
    ((seller tx-sender))
    (match (map-get? energy-offers { offer-id: offer-id })
      offer (begin
        (asserts! (is-eq seller (get seller offer)) (err u403))
        (map-delete energy-offers { offer-id: offer-id })
        (ok true)
      )
      (err u404)
    )
  )
)

(define-read-only (get-offer (offer-id uint))
  (map-get? energy-offers { offer-id: offer-id })
)

