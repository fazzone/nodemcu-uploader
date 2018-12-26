;;constants
(local cal-intercept -17800)
(local cal-coeff 11010.8)
;;gpio pins todo
;; other survey "https://docs.google.com/forms/d/e/1FAIpQLSelOx6I1Mv7x6Xg7f7vti9Qx7y5hQHms9LdCpZhYFutPZfZOg/formResponse"
;; entry "entry.1803841049"
(local the-survey-url "/forms/d/e/1FAIpQLSc27KLo5aBIgx45hESfawyI4q3KHZmnmVlG89K0aZoAZTOb-A/formResponse")
(local the-entry-key "entry.481836690")

;; scale control
(local lock-threshold 0.2) ;stddev units

;; device init
(fn display-create []
    (i2c.setup 0 2 1 i2c.SLOW)
    (u8g2.ssd1306_i2c_128x64_noname 0 0x3c))

(fn u8g2-setup [display]
    (: display :setFontRefHeightExtendedText)
    (: display :setDrawColor 1)
    (: display :setFontPosBottom)
    (: display :setFontDirection 0))

;; sending to google

(fn make-http-request
    [method url headers body]
    (var request (.. method " " url " HTTP/1.1\r\n"))
    (each [hdr val (pairs headers)]
	  (set request (.. request hdr ": " val "\r\n")))
    (.. request "Content-Length: " (# body) "\r\n\r\n" body))

(fn send-survey-datapoint-request
  [survey-url entry-key data]
  (make-http-request "POST"
                     survey-url
                     {"Host" "docs.google.com"
                      "Content-Type" "application/x-www-form-urlencoded"}
                     (.. entry-key "=" data)))

(fn send-via-forwarder
  [datapoint]
  (http.post "http://54.245.181.150:4321"
             nil
             (sjson.encode {:survey-path the-survey-url
                            :data {the-entry-key datapoint}})
             (fn [code data]
               (print "got response " code))))

(fn send-to-survey
  [data]
  (print "sending " data)
  (let [srv (tls.createConnection)]
    (: srv :on "receive"
       (fn [socket]
         (print "received first data")
         (: socket :close))
       (: srv :on "connection"
          (fn [socket c]
            (print "connected")
            (: socket :send (send-survey-datapoint-request the-survey-url the-entry-key data)))))
    (print "connecting")
    (: srv :connect 443 "docs.google.com")
    (print "connected?")))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn ring-buffer [size]
  (var points [])
  (var index 1)
  {:values (fn [this]
             (var i 0)
             (fn []
               (set i (+ i 1))
               (. points i)))
   :push (fn [this v] 
           (tset points index v)
           (set index (+ index 1))
           (when (< size index)
             (set index 1)))})

(fn average
  [iter]
  (var acc 0)
  (var count 0)
  (each [item iter]
        (set acc (+ acc item))
        (set count (+ 1 count)))
  (/ acc count))

(fn stddev
  [avg iter]
  (var acc 0)
  (var count 0)
  (each [item iter]
        (let [d (- item avg) ]
          (set acc (+ acc (* d d)))
          (set count (+ 1 count))))
  (math.sqrt (/ acc count)))

(fn read-scale []
    (tmr.delay 500)
    (/ (+ (hx711.read) cal-intercept) cal-coeff))

(global display (display-create))

(u8g2-setup display)

(hx711.init 4 0)

(global pending-send nil)

(node.egc.setmode node.egc.ON_MEM_LIMIT 16384)
(print "free: " (node.heap))

(let [t (tmr.create)
      sender-timer (tmr.create)
      buf (ring-buffer 3)]     
  (: sender-timer :register 5000 tmr.ALARM_SEMI
     (fn [t]
       (print "pending-send = " pending-send)
       (when pending-send
         ;; (send-to-survey pending-send)
         (send-via-forwarder pending-send)
         (global pending-send nil))
       (: sender-timer :start)))
  (: sender-timer :start)

  (: t :register 500 tmr.ALARM_SEMI
     (fn [t]
       (let [reading (read-scale)]
         (when (< 10 reading)
           (: buf :push reading)
           (let [avg (average (: buf :values))
                 std (stddev avg (: buf :values))]
             (print "m,s = " avg ", " std)
             (if (< std lock-threshold)
               (global pending-send avg)))))
       (: t :start)))

  (: t :start))
