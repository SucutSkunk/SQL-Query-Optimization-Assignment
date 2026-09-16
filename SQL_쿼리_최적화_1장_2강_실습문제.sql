
============================================================
필수 1. EXPLAIN과 EXPLAIN ANALYZE 비교 (문제 1-1)
============================================================


-- 1. SELECT문
select * from orders where order_id = 150000;

-- 2. EXPLAIN
explain
select * from orders where order_id = 150000;

-- 3. EXPLAIN ANALYZE
explain analyze
select * from orders where order_id = 150000;

/*
[주요 실행계획 항목] 
- 스캔 방식: Parallel Seq Scan 
- cost 시작 비용: 1000.00
- cost 총 비용: 5116.98
- 예상 rows: 1
- actual rows: 1.00
- Execution Time: 75.98

[Q1] EXPLAIN ANALYZE에서 EXPLAIN보다 추가로 확인할 수 있는 정보는 무엇인가요?
-> EXPLAIN은 쿼리를 실제로 실행하지 않고 옵티마이저가 세운 예상 계획만 보여준다.
   반면 EXPLAIN ANALYZE는 쿼리를 실제로 실행까지 하기 때문에, actual time, actual rows, loops,
   Rows Removed by Filter, Buffers, Execution Time처럼 실제 실행 결과에 대한 정보를 추가로 확인할 수 있다.

[Q2] cost는 실제 실행 시간(ms)인가요?
-> 아니다. cost는 옵티마이저가 여러 실행계획을 비교하기 위해 사용하는 상대적인 비용 단위일 뿐이다. 
*/


/*
============================================================
필수 2. JOIN 실행계획 읽기 (문제 2-1)
============================================================
*/

-- 1~2. SELECT문 + EXPLAIN ANALYZE
explain analyze
select o.order_id, o.order_date, o.customer_id, c.city
from orders o
join customers c on o.customer_id = c.customer_id
where order_date >= DATE '2023-01-01' and order_date < DATE '2024-01-01';

/*
[테이블별 스캔 방식]
- orders: Seq Scan
- customers: Seq Scan

[조인 방식]
- Hash Join

[주요 노드의 예상 rows / actual rows]
- Hash Join: 예상 76,120 / 실제 75,023.00
- Seq Scan on orders: 예상 76,120 / 실제 75,023.00
- Seq Scan on customers (Hash): 예상 50,000 / 실제 50,000.00

[처리 순서] (아래쪽 -> 위쪽)
1. Seq Scan on customers: customers 50,000행 전체를 읽는다.
2. Hash: 읽어온 customers 데이터로 customer_id를 키로 하는 해시 테이블을 메모리에 만든다.
3. Seq Scan on orders: orders 300,000행을 읽으며 order_date 조건에 맞는 75,023행만 남기고
   나머지 224,977행은 걸러낸다.
4. Hash Join: 3번에서 걸러진 orders 행마다 customer_id로 2번의 해시 테이블을 조회해서
   일치하는 customer 정보를 합쳐 최종 결과를 만든다.
   위쪽 노드는 아래쪽 노드가 만든 결과를 받아야만 동작할 수 있으므로, 아래에서 위로 읽어야 실제
   처리 순서를 정확히 이해할 수 있다.

[Rows Removed by Filter 해석]
조건에 해당하지 않아 걸러진 행들의 수가 출력된다.

[Q1] JOIN 실행계획을 아래쪽 노드부터 읽는 이유는 무엇인가요?
-> 부모 노드는 자식 노드가 만들어낸 결과를 받아야 작동하기 때문이다. 아래쪽부터 읽어야 실제 데이터가 처리되는 순서 그대로 이해할 수 있다.

[Q2] 예상 rows와 actual rows 차이가 크다면 무엇을 점검할 수 있나요?
-> 통계량 업데이트가 되지 않았을 수 있다. analyze로 업데이트가 필요하다. 

[Q3] orders와 customers의 Scan 노드에 표시된 actual rows와 Rows Removed by Filter는 각각 무엇을 의미하나요?
-> actual rows는 해당 스캔 노드가 실제로 조건을 통과해 다음 단계로 넘긴 행의 수이다.
   Rows Removed by Filter는 스캔 도중 조건에 맞지 않아 제외된 행의 수이다.
*/


/*
============================================================
과제. order_items 실행계획 해석 (문제 3-1)
============================================================
*/

-- 1~2. SELECT문
select
  order_item_id,
  order_id,
  product_id,
  qty,
  price
from order_items
where product_id = 100;

-- 3. EXPLAIN
explain
select
  order_item_id,
  order_id,
  product_id,
  qty,
  price
from order_items
where product_id = 100;

-- 4. EXPLAIN ANALYZE
explain analyze
select
  order_item_id,
  order_id,
  product_id,
  qty,
  price
from order_items
where product_id = 100;

/*
[주요 실행계획 항목] 
- 스캔 방식: Parallel Seq Scan
- cost 시작 비용 / 총 비용: 1000.00 / 7953.00
- 예상 rows: 60
- actual rows: 48
- Rows Removed by Filter: 199984
- Execution Time: 3.233

[예상 rows와 actual rows 비교]
-> 옵티마이저는 product_id 값의 분포가 고르다고 가정하고 추정치를 계산하지만,
   실제로는 특정 product_id에 몰린 주문 수가 평균보다 많거나 적을 수 있어 차이가 날 수 있다.
   본인 결과에서 두 값을 비교해, 차이가 작으면 통계가 잘 맞은 것이고 크면 분포가 고르지 않다는 뜻이다.

[Q1] 가장 먼저 확인해야 할 데이터 접근 방식은 무엇인가요?
-> 스캔 방식을 가장 먼저 확인해야 한다.
   인덱스 없이 전체 테이블을 훑는지, 인덱스를 타고 바로 찾아가는지에 따라 성능 차이가 크기 때문이다.

[Q2] Seq Scan은 테이블의 데이터를 어떤 방식으로 확인하나요?
-> 테이블의 첫 번째 행부터 마지막 행까지 순서대로 순차적으로 하나씩 읽으면서
   조건에 맞는지 검사하는 방식이다. 인덱스를 사용하지 않기 때문에 테이블 전체를 다 읽어야 한다.
*/


/*
============================================================
실습 마무리
============================================================
*/

/*
1. EXPLAIN과 EXPLAIN ANALYZE의 가장 중요한 차이는 무엇인가요?
-> EXPLAIN은 실제로 쿼리를 실행하지 않고 예상 계획만 보여주고,
   EXPLAIN ANALYZE는 실제로 실행까지 해서 실제 시간과 실제 rows까지 함께 보여준다.

2. 스캔 방식과 처리 행 수를 함께 확인하면 무엇을 알 수 있나요?
-> 어떤 방식으로 데이터에 접근했는지와, 그 과정에서 얼마나 많은 행을 읽고 걸러냈는지를 함께 보면, 
이 쿼리가 효율적으로 실행됐는지 아니면 불필요하게 많은 데이터를 읽었는지 판단할 수 있다.

3. JOIN 실행계획은 어떤 순서로 읽는 것이 좋나요?
-> 트리 구조의 자식 노드부터 부모 노드 방향으로 읽는 것이 좋다.
   데이터가 실제로 아래에서 위로 흘러가며 처리되기 때문이다.
*/