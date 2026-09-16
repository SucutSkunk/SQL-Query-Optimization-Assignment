/*
============================================================
[5장 1강] 실습문제: EXPLAIN 결과 해석과 실행계획 요소 식별
============================================================

[실습 목표]
- 복합 쿼리의 EXPLAIN 결과를 아래에서 위로 읽을 수 있다.
- Scan, Join, Sort, Aggregate, WindowAgg 노드를 식별할 수 있다.
- cost, rows, actual rows, actual time의 의미를 구분할 수 있다.
- 실행계획에서 병목 후보 노드를 찾을 수 있다.
- 실행계획을 바탕으로 개선 방향 후보를 설명할 수 있다.

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
- orders
- order_items
- customers

[주요 관계]
- orders.order_id = order_items.order_id
- orders.customer_id = customers.customer_id

[주의사항]
- 실행계획의 cost와 actual time은 환경에 따라 달라질 수 있습니다.
- 특정 숫자를 외우는 것이 아니라, 어떤 노드가 어떤 작업을 하는지 해석하는 것이 핵심입니다.
*/


/*
============================================================
과제. JOIN + 정렬 실행계획 해석
============================================================

[문제 3-1] 고객 주문 조회 실행계획 분석

[문제 설명]
고객 주문 정보를 조회하면서
주문일 기준으로 정렬하는 쿼리의 실행계획을 분석하세요.

이번 문제에서는 실행계획에서
Scan → Join → Sort 흐름을 직접 확인하는 것이 핵심입니다.

※ 과제는 필수 문제와 동일한 수준입니다.

[요구사항]
1. orders와 customers를 customer_id 기준으로 JOIN하세요.
2. 2023년 주문만 조회하세요.
3. 다음 컬럼을 조회하세요.
   - orders.order_id
   - orders.order_date
   - customers.customer_id
   - customers.city
4. 결과를 order_date DESC로 정렬하세요.
5. EXPLAIN ANALYZE를 적용하세요.
6. 실행계획에서 다음 항목을 확인하세요.
   - orders Scan 방식
   - customers Scan 방식
   - Join 방식
   - Sort
   - estimated rows
   - actual rows
   - Execution Time
7. 실행계획을 아래에서 위로 읽으면서 실제 처리 흐름을 설명하세요.
8. 가장 먼저 확인할 병목 후보 노드를 하나 선택하고 이유를 작성하세요.
9. 다음 질문에 답하세요.
   Q1. Scan 노드에서는 무엇을 확인해야 하나요?
   Q2. Join 노드에서는 무엇을 확인해야 하나요?
   Q3. Sort 노드에서는 무엇을 확인해야 하나요?
   Q4. Seq Scan이 나타났다고 해서 무조건 잘못된 실행계획이라고 할 수 있나요?

[제출 결과]
- 전체 SQL
- EXPLAIN ANALYZE 결과
- 실행 흐름
- 병목 후보
- Q1~Q4 답변
*/

-- [코드 작성란]
EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_date,
    c.customer_id,
    c.city
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date >= '2023-01-01'
  AND o.order_date <  '2024-01-01'
ORDER BY o.order_date DESC;

/*
 * 7. 실행계획을 읽으면서 실제 처리 흐름 설명
 *Seq Scan on orders: orders 테이블 전체를 순차 스캔하면서 order_date 조건(2023년)을 만족하는 행만 남깁니다. 
 *조건에 안 맞는 행 56만여 건이 Rows Removed by Filter로 걸러지고, 3만여 건만 다음 단계로 넘어갑니다.
 *
 *Seq Scan on customers → Hash: customers 테이블을 순차 스캔해 읽은 뒤 해시 테이블로 만듭니다(조인 준비 단계).
 *
 *Hash Join: 위에서 필터링된 orders 행과 customers 해시 테이블을 customer_id 기준으로 연결합니다.
 *
 *Sort: 조인된 결과를 order_date DESC 기준으로 정렬해 최종 결과를 만듭니다.

즉 "orders에서 2023년 주문 걸러내기 → customers 읽어서 해시 만들기 → 두 결과 조인 → 날짜순 정렬"의 순서로 처리됩니다.
 */



/*
============================================================
실습 마무리
============================================================

아래 내용을 한 문단으로 정리하세요.

1. 실행계획은 왜 아래에서 위로 읽는 것이 좋은가요?
2. Scan, Join, Sort, WindowAgg는 각각 어떤 작업을 의미하나요?
3. cost와 actual time은 어떻게 다른가요?
4. 병목 노드를 찾을 때 어떤 정보를 함께 봐야 하나요?

실행계획은 가장 안쪽(리프) 노드에서 실제 데이터 조회가 먼저 일어나고 그 결과가 바깥쪽 노드로 전달되는 트리 구조이기 때문에 
아래에서 위로 읽어야 실제 처리 순서(데이터 읽기 → 필터링 → 조인 → 정렬 → 집계)를 그대로 따라갈 수 있고, 

Scan은 테이블에서 데이터를 읽는 작업을, Join은 두 결과 집합을 연결하는 작업을, Sort는 지정한 기준으로 데이터를 정렬하는 작업을, WindowAgg는 윈도우 함수 계산을 수행하는 작업을 의미하며, 

cost는 옵티마이저가 예측한 비용일 뿐 실제 실행 시간이 아니고 actual time은 EXPLAIN ANALYZE로 쿼리를 실제로 실행했을 때 각 노드에서 걸린 진짜 시간이라는 점에서 다르고, 

병목 노드를 찾을 때는 특정 노드 하나의 cost나 actual time만 보지 말고 
전체 비용에서 해당 노드가 차지하는 비중, 예상 rows와 실제 rows의 차이, 정렬이나 조인 과정에서 디스크를 사용했는지 여부 등 여러 정보를 함께 살펴봐야 한다.
*/
