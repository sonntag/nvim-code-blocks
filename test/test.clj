;; Test Clojure file for code block highlighting

(ns test-blocks
  (:require [clojure.string :as str]))

(defn outer-function
  "An outer function with nested forms"
  []
  (println "outer start")

  (let [inner-fn (fn []
                   (println "inner start")
                   (when true
                     (println "inside when")
                     (let [x 1
                           y 2]
                       (+ x y)))
                   (println "inner end"))]

    (inner-fn)
    (println "outer end")))

(defn process-numbers
  "Process a collection of numbers"
  [numbers]
  (map (fn [n]
         (if (even? n)
           (* n 2)
           (+ n 1)))
       numbers))

(defn deeply-nested
  "Test deeply nested structures"
  []
  (let [a 1]
    (when (pos? a)
      (doseq [i (range 5)]
        (when (even? i)
          (println i))))))

;; Vector literal
[1 2 3
 4 5 6
 7 8 9]

;; Map literal
{:name "Test"
 :value 42
 :nested {:a 1
          :b 2}}

;; Set literal
#{:foo :bar
  :baz :qux}

(comment
  (outer-function)
  (process-numbers [1 2 3 4 5])
  (deeply-nested))
