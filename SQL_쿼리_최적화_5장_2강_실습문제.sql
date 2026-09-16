/*
============================================================
[5장 2강] 실습문제: 쿼리 재작성 전후 실행계획 비교와 개선 효과 분석
============================================================

[실습 목표]
- 튜닝 전 실행계획과 실행 시간을 기준값으로 기록할 수 있다.
- 인덱스 추가 전후의 실행계획 변화를 비교할 수 있다.
- 쿼리 재작성 전후의 실행계획 변화를 비교할 수 있다.
- cost, 스캔 방식, Execution Time을 근거로 개선 효과를 판단할 수 있다.
- 개선이 항상 발생하는 것은 아니라는 점을 실행계획으로 설명할 수 있다.

[사용 환경]
- PostgreSQL
- DBeaver

[사용 데이터]
이번 과정에서는 아래 12개 CSV로 구성된 동일한 Retail Data Warehouse 데이터셋을 계속 사용합니다.

- customers
- employees
- order_items
- orders
- payments
- products
- promotions
- returns
- shipments
- stores
- suppliers
- categories

[이번 강에서 주로 사용하는 테이블]
- order_items
- orders

[주의사항]
- 실행계획의 cost와 Execution Time은 PostgreSQL 버전, 서버 환경,
  캐시 상태, 통계정보 등에 따라 달라질 수 있습니다.
- 개선 전후에는 비교 대상 SQL의 조건을 동일하게 유지해야 합니다.
- 한 번에 여러 요소를 변경하지 않고 한 가지 변경만 적용하여
  무엇 때문에 실행계획이 달라졌는지 확인합니다.
*/

/*
============================================================
과제. JOIN 쿼리의 날짜 인덱스 적용 전후 개선 효과 분석
============================================================

[문제 3-1] 고객 도시 정보를 포함한 특정 기간 주문 조회 튜닝 결과 보고

[문제 설명]
운영 리포트에서 2023년 12월 주문과 고객 도시 정보를 함께 조회하고,
최근 주문부터 확인하는 쿼리를 반복적으로 사용한다고 가정합니다.

orders와 customers를 customer_id 기준으로 JOIN한 상태에서
먼저 현재 실행계획을 기준값으로 기록한 뒤,
orders.order_date 인덱스를 추가하여 동일한 JOIN 쿼리를 다시 측정하세요.

마지막에는 Scan → Join → Sort 흐름과 실행계획 변화,
실행시간 개선 효과와 한계를 간단한 비교 보고서 형태로 정리하세요.

※ 과제는 필수 문제와 동일한 수준입니다.

[요구사항]
1. 기존 idx_orders_order_date 인덱스가 있다면 삭제하세요.
2. orders와 customers를 customer_id 기준으로 JOIN하세요.
3. 다음 기간의 주문만 조회하세요.

   orders.order_date >= DATE '2023-12-01'
   orders.order_date <  DATE '2024-01-01'

4. 다음 컬럼을 출력하세요.
   - orders.order_id
   - orders.order_date
   - customers.customer_id
   - customers.city
5. 결과를 orders.order_date DESC로 정렬하세요.
6. 인덱스 생성 전 EXPLAIN ANALYZE 결과에서 다음 항목을 기록하세요.
   - orders 스캔 방식
   - customers 스캔 방식
   - Join 방식
   - JOIN 조건
   - Sort 여부
   - total cost
   - actual rows
   - Execution Time
7. orders.order_date에 idx_orders_order_date 인덱스를 생성하세요.
8. 동일한 JOIN 쿼리에 다시 EXPLAIN ANALYZE를 적용하세요.
9. 개선 후 동일한 항목을 기록하세요.
10. Join 노드가 개선 전후에 어떻게 달라졌는지 확인하세요.
    - Join 방식이 변경되었는지
    - Join 입력 행 수가 달라졌는지
    - Join 노드의 cost 또는 actual time이 달라졌는지
11. 실행시간 감소율을 다음 식으로 계산하세요.

   (개선 전 Execution Time - 개선 후 Execution Time)
   / 개선 전 Execution Time * 100

12. 다음 형식으로 비교 결과를 정리하세요.

   항목                  개선 전        개선 후
   ----------------------------------------------------
   orders 스캔 방식
   customers 스캔 방식
   Join 방식
   JOIN 조건
   Sort 여부
   Join 노드 변화
   total cost
   actual rows
   Execution Time
   실행시간 감소율

13. 다음 질문에 답하세요.
    Q1. 인덱스 추가 후에도 Sort가 남을 수 있나요?
    Q2. 인덱스를 추가했는데 옵티마이저가 Seq Scan을 계속 선택한다면 어떤 의미인가요?
    Q3. Join 방식이 변경되었다고 해서 반드시 성능이 개선되었다고 말할 수 있나요?
    Q4. 이번 결과만으로 모든 날짜 JOIN 조회에 order_date 인덱스가 항상 효과적이라고 결론 내릴 수 있나요?
14. 실습 종료 후 idx_orders_order_date 인덱스를 삭제하세요.

[제출 결과]
- 전체 JOIN SQL
- 개선 전 EXPLAIN ANALYZE
- CREATE INDEX 문
- 개선 후 EXPLAIN ANALYZE
- Scan / Join / Sort 비교표
- JOIN 조건 확인
- Join 노드 전후 변화 해석
- 실행시간 감소율
- Q1~Q4 답변
- DROP INDEX 문
*/

-- [코드 작성란]
DROP INDEX IF EXISTS idx_orders_order_date;

EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.city
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date >= DATE '2023-12-01'
  AND o.order_date <  DATE '2024-01-01'
ORDER BY o.order_date DESC;

/*
 * 6.
-- orders 스캔 방식   : Parallel Seq Scan on orders o--                     
-- customers 스캔 방식 : Seq Scan on customers c 
-- Join 방식          : Hash Join
-- JOIN 조건          : Hash Cond: (o.customer_id = c.customer_id)
-- Sort 여부          : 있음 
-- total cost         : 7245.95..7986.19  
-- actual rows        : 6344             
-- Execution Time     : 70.381 ms
--
-- 흐름: Parallel Seq Scan(orders, 필터링)
--       -> Hash Join(customer_id 기준, customers 해시)
--       -> Sort(order_date DESC, 워커별)
--       -> Gather Merge(워커 결과 병합)
-- ============================================================
 */

CREATE INDEX idx_orders_order_date
ON orders(order_date);

-- 9.
-- orders 스캔 방식   : Bitmap Heap Scan on orders o
-- customers 스캔 방식 : Seq Scan on customers c 
-- Join 방식          : Hash Join
-- JOIN 조건          : Hash Cond: (o.customer_id = c.customer_id)
-- Sort 여부          : 있음 
-- total cost         : 4008.03..4024.26  
-- actual rows        : 6344              
-- Execution Time     : 9.512 ms
--
-- 흐름: Bitmap Index Scan(idx_orders_order_date, 조건 위치 탐색)
--       -> Bitmap Heap Scan(orders, 실제 행 조회)
--       -> Hash Join(customer_id 기준, customers 해시)
--       -> Sort(order_date DESC)
-- ============================================================

-- 10.
-- [Join 방식 변경 여부]
--   변경 없음. 개선 전/후 모두 Hash Join 사용.
--   (Hash Cond: (o.customer_id = c.customer_id) 동일)
--
-- [Join 입력 행 수 변화]
--   개선 전: Parallel Seq Scan on orders → rows=3172 * loops=2(워커 2개)
--            = 총 6344건이 나뉘어 Hash Join에 투입됨
--   개선 후: Bitmap Heap Scan on orders → rows=6344 * loops=1
--            = 단일 실행으로 6344건이 한 번에 Hash Join에 투입됨
--   customers 쪽 입력(Hash): 개선 전/후 모두 50000건으로 동일
--   → 최종 처리 행 수 자체(6344건)는 동일하지만,
--     병렬 분산 처리에서 단일 처리로 바뀜
--
-- [Join 노드 cost / actual time 변화]
--   개선 전: cost=1408.00..6018.60   actual time=2.465..6.457 (2 loops)
--   개선 후: cost=1499.00..3596.73   actual time=5.168..8.445 (1 loop)
--   → cost 상/하한 폭: (6018.60-1408.00)=4610.60
--                    → (3596.73-1499.00)=2097.73   약 54.5% 감소
--   ※ 개선 전 actual time은 병렬 워커 기준(2 loops)으로 표기되어 있어
--     개선 후(단일 실행, 1 loop)와 절대 시간 비교 시 실행 구조 차이를
--     감안해서 봐야 함. 다만 orders 스캔이 Bitmap Index Scan으로
--     바뀌면서 Join 이전 단계에서 불필요한 행을 훨씬 적게 만들어
--     Join 노드 자체의 cost 폭이 줄어든 것이 핵심 변화.
-- ============================================================


-- ============================================================
-- 11. 실행시간 감소율 계산
-- ============================================================
--
-- 개선 전 Execution Time : 70.381 ms
-- 개선 후 Execution Time :  9.512 ms
--
-- 감소율 = (70.381 - 9.512) / 70.381 × 100
--        = 60.869 / 70.381 × 100
--        ≈ 86.49 %
-- ============================================================


-- ============================================================
-- 12. 개선 전후 비교표
-- ============================================================
--
-- 항목                  개선 전                          개선 후
-- ------------------------------------------------------------------------------------
-- orders 스캔 방식      Parallel Seq Scan on orders      Bitmap Heap Scan on orders
--                                                        (idx_orders_order_date 이용)
-- customers 스캔 방식   Seq Scan on customers            Seq Scan on customers
-- Join 방식             Hash Join                        Hash Join
-- JOIN 조건             o.customer_id = c.customer_id    o.customer_id = c.customer_id
-- Sort 여부             있음 (quicksort, 440kB,          있음 (quicksort, 440kB)
--                       워커별 정렬 + Gather Merge)
-- Join 노드 변화        cost=1408.00..6018.60            cost=1499.00..3596.73
--                       actual=2.465..6.457 (2 loops)    actual=5.168..8.445 (1 loop)
--                       → 알고리즘 동일, cost 폭 약 54.5% 감소
-- total cost            7245.95..7986.19                 4008.03..4024.26
-- actual rows           6344                              6344
-- Execution Time        70.381 ms                         9.512 ms
-- 실행시간 감소율       -                                  약 86.49%
-- ============================================================
/*
 * 
 * -- ============================================================
-- 13. Q1~Q4 답변
-- ============================================================
--
-- Q1. 인덱스 추가 후에도 Sort가 남을 수 있나요?
--     네, 실제로 남았습니다. 개선 후 결과에서도
--     Bitmap Heap Scan/Bitmap Index Scan으로 orders 스캔은
--     빨라졌지만, 최상위 노드는 여전히
--     "Sort (Sort Key: o.order_date DESC, quicksort, 440kB)"
--     입니다. 인덱스는 order_date 조건으로 행을 "찾는" 단계만
--     빠르게 해줄 뿐, Hash Join으로 두 테이블을 합친 결과는
--     순서가 보장되지 않기 때문에 ORDER BY를 만족시키려면
--     별도의 Sort 노드가 그대로 필요합니다.
--
-- Q2. 인덱스를 추가했는데 옵티마이저가 계속 Seq Scan을 선택한다면
--     어떤 의미인가요?
--     이번 실습에서는 옵티마이저가 Bitmap Index Scan을 선택해
--     인덱스가 실제로 사용되었지만, 만약 인덱스를 만들어도
--     계속 Seq Scan이 선택된다면 이는 옵티마이저가 통계와 비용
--     추정을 근거로 "이 조건에서는 인덱스보다 순차 스캔이 더
--     저렴하다"고 판단했다는 의미입니다. 조회 대상 행의 비율
--     (선택도)이 너무 높거나, 테이블이 작거나, 통계 정보
--     (ANALYZE)가 최신이 아닌 경우에 흔히 나타납니다.
--
-- Q3. Join 방식이 변경되었다고 해서 반드시 성능이 개선되었다고
--     말할 수 있나요?
--     아니요. 이번 사례가 오히려 좋은 반례입니다 — Join 방식은
--     개선 전/후 모두 Hash Join으로 "전혀 바뀌지 않았지만",
--     orders 스캔 방식이 Parallel Seq Scan에서 Bitmap Heap
--     Scan으로 바뀐 덕분에 Execution Time이 70.381ms →
--     9.512ms로 크게 줄었습니다. 즉 성능 개선 여부는 Join
--     방식의 변경 유무가 아니라, cost와 actual time 같은
--     실측값으로 직접 확인해야 합니다. (반대로 Join 방식이
--     바뀌었어도 성능이 나빠지는 경우도 있을 수 있습니다.)
--
-- Q4. 이번 결과만으로 모든 날짜 JOIN 조회에 order_date 인덱스가
--     항상 효과적이라고 결론 내릴 수 있나요?
--     아니요. 이번 조건(2023년 12월 한 달, 전체 orders 중
--     일부만 해당)처럼 선택도가 낮을 때는 인덱스가 효과적이었
--     지만, 조회 기간이 훨씬 넓어져 조건에 맞는 행의 비율이
--     커지면 옵티마이저가 다시 Seq Scan을 선택할 수도 있습니다.
--     따라서 다른 기간·다른 조건에서도 반복적으로
--     EXPLAIN ANALYZE로 검증해야 일반화할 수 있습니다.
-- ============================================================


-- ============================================================
-- 실습 마무리 정리
-- ============================================================
-- 튜닝 전에 기준 실행계획을 먼저 기록해두어야 인덱스를 추가한
-- 뒤 무엇이 얼마나 개선되었는지 비교할 근거가 생기며, 인덱스
-- 추가나 쿼리 재작성 후에는 반드시 동일한 쿼리로 EXPLAIN
-- ANALYZE를 다시 실행해 스캔 방식(Parallel Seq Scan →
-- Bitmap Heap/Index Scan), Join 방식, Sort 여부, cost,
-- actual rows, Execution Time을 재측정해야 하고, 튜닝 효과를
-- 설명할 때는 이 지표들을 개선 전후로 나란히 비교해 실행시간
-- 감소율(이번 사례에서는 약 86.49%) 같은 숫자로 제시해야
-- 설득력이 생긴다. 마지막으로 이번 실습에서 확인했듯이
-- Join 방식(Hash Join) 자체는 개선 전후로 전혀 바뀌지 않았고
-- Sort 노드도 그대로 남아 있었지만 성능은 크게 개선되었는데,
-- 이는 orders 스캔 방식이 Parallel Seq Scan에서
-- Bitmap Index/Heap Scan으로 바뀌어 조건에 맞지 않는 행을
-- 미리 훨씬 적게 읽게 되었기 때문이다. 따라서 실행계획의 특정
-- 노드나 방식이 바뀌었다는 사실 하나만으로 성능 개선을
-- 확정할 수 없고, 항상 cost·actual rows·Execution Time 같은
-- 실측 지표로 직접 확인해야 하며, 이번 결과 역시 특정 조회
-- 조건(선택도가 낮은 한 달치 기간)에서 얻은 것이므로 다른
-- 조건에도 항상 동일하게 적용된다고 일반화할 수 없다는 점을
-- 함께 기억해야 한다.
-- ============================================================
*/
