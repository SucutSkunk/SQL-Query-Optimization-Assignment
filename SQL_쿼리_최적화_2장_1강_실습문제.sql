/*
============================================================
[2장 1강] 실습문제: 인덱스 구조와 동작 원리
============================================================

[실습 목표]
- B-Tree 인덱스가 검색 범위를 줄여 데이터를 탐색하는 원리를 이해할 수 있다.
- CREATE INDEX와 DROP INDEX를 이용하여 인덱스를 생성하고 삭제할 수 있다.
- EXPLAIN ANALYZE를 이용하여 인덱스 생성 전후의 실행계획을 비교할 수 있다.
- pg_indexes를 이용하여 생성된 인덱스 목록을 확인할 수 있다.
- 인덱스 생성에 따라 INSERT, UPDATE, DELETE 시 추가 작업이 필요한 이유를 설명할 수 있다.

[사용 환경]
- PostgreSQL
- DBeaver

[사용 데이터]
- orders      : 300,000행
- products    : 10,000행

[주의사항]
- 실행 시간과 cost는 PostgreSQL 환경에 따라 달라질 수 있습니다.
- 특정 실행계획 형태를 정답으로 고정하지 않습니다.
- 학생은 자신의 EXPLAIN ANALYZE 결과를 기준으로 작성합니다.
*/


/*
============================================================
실습 준비
============================================================
*/

SELECT COUNT(*) AS order_count
FROM orders;

SELECT COUNT(*) AS product_count
FROM products;


/*
============================================================
필수 1. customer_id 인덱스 생성 전후 비교
============================================================

[문제 1-1]

[문제 설명]
orders에서 특정 고객의 주문을 조회할 때
customer_id 인덱스 생성 전후의 실행계획이 어떻게 달라지는지 확인하세요.

[요구사항]
1. idx_orders_customer_id 인덱스가 있다면 삭제하세요.
2. customer_id = 31428 조건으로 주문을 조회하고 EXPLAIN ANALYZE를 적용하세요.
3. 인덱스 생성 전 실행계획에서 다음 항목을 기록하세요.
   - 스캔 방식
   - cost
   - actual rows
   - Execution Time
4. orders.customer_id에 idx_orders_customer_id 인덱스를 생성하세요.
5. 동일한 SELECT문에 다시 EXPLAIN ANALYZE를 적용하세요.
6. 인덱스 생성 후 실행계획에서 다음 항목을 기록하세요.
   - 스캔 방식
   - cost
   - actual rows
   - Execution Time
7. 인덱스 생성 전후 결과를 비교하세요.
8. 다음 질문에 답하세요.
   Q1. 인덱스 생성 전과 후의 스캔 방식은 어떻게 달라졌나요?
   Q2. B-Tree 인덱스가 customer_id = 31428을 찾을 때
       모든 주문을 처음부터 확인하지 않아도 되는 이유는 무엇인가요?
   Q3. cost와 Execution Time은 같은 의미인가요?

[제출 결과]
- DROP INDEX 문
- 인덱스 생성 전 EXPLAIN ANALYZE
- 개선 전 기록표
- CREATE INDEX 문
- 인덱스 생성 후 EXPLAIN ANALYZE
- 개선 후 기록표
- 전후 비교
- Q1~Q3 답변
*/

-- [코드 작성란]
--1.
drop index if exists idx_orders_customer_id;

--2.
select *
from orders
where customer_id = 31428;

explain analyze
select *
from orders
where customer_id = 31428;

/*
3.
스캔 방식: Parallel Seq Scan on orders
cost: 1000.00 / 5117.58
actual rows: 19.00
Execution Time: 70.666
*/

--4.
create index idx_orders_customer_id
on orders(customer_id);

--5.
explain analyze
select *
from orders
where customer_id = 31428;

/*
6. 
스캔 방식: Bitmap Heap Scan on orders
cost: 4.48 / 31.29
actual rows: 19.00
Execution Time: 0.058
 */

/*
7.
스캔 방식이 바뀌었다.
인덱스를 생성한 후 cost가 약 5117에서 약 31로 큰 폭으로 감소했다.
actual rows는 동일하다.
Execution Time이 70.666에서 0.058로 큰 폭으로 감소했다.
*/

/*
 * 8.
 * Q1. 인덱스 생성 전과 후의 스캔 방식은 어떻게 달라졌나요?
 * Parallel Seq Scan on orders 방식의 full scan 형태에서
 * Bitmap Heap Scan on orders 방식의 인덱스를 타는 형태로 바뀌었다.
 * 
 * Q2. 
 * customer_id 가 31428인 경우만 찾으면 되므로 
 * 해당 값이 있는 범위로 빠르게 찾아들어갈 수 있기 때문이다.
 * 
 * Q3. 
 * 다릅니다. 우선 단위부터 다릅니다.
 * cost는 절대적인 단위가 존재하는 것이 아닌 optimizer가 스캔 방식을 정하기 위한 추상적인 단위이고
 * 반면에 Execution Time은 ms 단위를 가지고 있습니다.
 * cost는 특정 스캔 방식으로 진행했을 때 들어가는 추상적인 비용이고 
 * Excution Time은 explain analyze를 했을 때 도출되는 실제 실행 시간을 의미합니다.
 */

/*
============================================================
필수 2. 인덱스 생성·확인·삭제와 쓰기 비용 이해
============================================================

[문제 2-1]

[문제 설명]
products 테이블의 category_id와 supplier_id 컬럼에
실습용 B-Tree 인덱스를 생성하고,
PostgreSQL 시스템 뷰에서 생성 결과를 확인한 뒤 삭제하세요.

인덱스 생성과 삭제 문법을 익히고,
테이블의 데이터가 변경될 때 관련 인덱스에도 추가 작업이 필요한 이유를 설명하세요.

[요구사항]
1. 다음 실습용 인덱스가 있다면 삭제하세요.
   - idx_products_category_practice
   - idx_products_supplier_practice
2. products.category_id에 idx_products_category_practice 인덱스를 생성하세요.
3. products.supplier_id에 idx_products_supplier_practice 인덱스를 생성하세요.
4. pg_indexes에서 products 테이블의 인덱스 이름과 정의를 조회하세요.
5. 조회 결과에서 두 실습용 인덱스가 생성되었는지 확인하세요.
6. 두 실습용 인덱스를 삭제하세요.
7. pg_indexes를 다시 조회하여 두 인덱스가 삭제되었는지 확인하세요.
8. 다음 질문에 답하세요.
   Q1. CREATE INDEX와 DROP INDEX는 각각 어떤 작업을 수행하나요?
   Q2. INSERT 시 테이블 외에 인덱스에도 추가 작업이 필요한 이유는 무엇인가요?
   Q3. 인덱스 컬럼을 UPDATE하거나 행을 DELETE할 때 인덱스에는 어떤 작업이 필요한가요?

[제출 결과]
- 기존 실습용 인덱스 DROP INDEX 문
- 두 개의 CREATE INDEX 문
- pg_indexes 확인 SQL과 생성 확인 결과
- 두 개의 DROP INDEX 문
- pg_indexes 재확인 SQL과 삭제 확인 결과
- 쓰기 작업 시 인덱스 유지 비용에 대한 설명
- Q1~Q3 답변
*/

-- [코드 작성란]
--1.
drop index if exists idx_products_category_practice;
drop index if exists idx_products_supplier_practice;

--2.
create index idx_products_category_practice
on products(category_id);

--3.
create index idx_products_supplier_practice
on products(supplier_id);

--4.
select indexname, indexdef
from pg_indexes
where tablename= 'products';

--5.
--생성 확인했음.

--6.
drop index if exists idx_products_category_practice;
drop index if exists idx_products_supplier_practice;

--7.
select indexname, indexdef
from pg_indexes
where tablename= 'products';
--삭제되었음을 확인했음.

/*
 * 8. 다음 질문에 답하세요.
 * Q1. 
 * CREATE INDEX는 인덱스(색인)을 만들어주고
 * DROP INDEX는 인덱스(색인)을 삭제한다.
 * 
 * Q2.
 * 인덱스는 특정 행을 기준으로 정렬을 유지해야 하는데,
 * DML 계열의 UPDATE, INSERT, DELETE 을 실행 할 때마다 정렬을 유지 시켜 주기 위해서
 * 추가 작업이 필요하다.
 * 
 * Q3. 
 * UPDATE로 인덱스 컬럼 값이 바뀌면, 인덱스는 기존 값의 엔트리를 삭제하고 새 값으로 다시 삽입해 정렬 위치를 재조정해야 합니다. 
 * DELETE로 행이 삭제되면, 그 행을 가리키던 인덱스 엔트리도 함께 제거해야 합니다.
 */


/*
============================================================
과제. 범위 검색에서 B-Tree 인덱스 확인
============================================================

[문제 3-1]

[문제 설명]
products.price에 B-Tree 인덱스를 생성하고
price가 100 이상 120 미만인 범위 조회의 실행계획을 비교하세요.

※ 필수 문제와 동일한 수준의 독립 실습입니다.

[요구사항]
1. products.price의 최솟값과 최댓값을 확인하세요.
2. idx_products_price 인덱스가 있다면 삭제하세요.
3. price >= 100 AND price < 120 조건에 EXPLAIN ANALYZE를 적용하세요.
4. 인덱스 생성 전 다음 항목을 기록하세요.
   - 스캔 방식
   - cost
   - actual rows
   - Execution Time
5. products.price에 idx_products_price 인덱스를 생성하세요.
6. 동일한 SELECT문에 다시 EXPLAIN ANALYZE를 적용하세요.
7. 인덱스 생성 후 다음 항목을 기록하세요.
   - 스캔 방식
   - cost
   - actual rows
   - Execution Time
8. 인덱스 생성 전후 결과를 비교하세요.
9. 실습이 끝나면 idx_products_price 인덱스를 삭제하세요.
10. 다음 질문에 답하세요.
    Q1. B-Tree 인덱스는 등호 검색 외에 어떤 비교 조건에 활용될 수 있나요?
    Q2. B-Tree 인덱스가 범위 검색에서 검색 범위를 줄일 수 있는 이유는 무엇인가요?
    Q3. 인덱스를 많이 만들수록 INSERT, UPDATE, DELETE 비용이 커질 수 있는 이유는 무엇인가요?

[제출 결과]
- MIN/MAX 확인 SQL
- DROP INDEX 문
- 인덱스 생성 전 EXPLAIN ANALYZE
- 개선 전 기록표
- CREATE INDEX 문
- 인덱스 생성 후 EXPLAIN ANALYZE
- 개선 후 기록표
- 전후 비교
- 최종 DROP INDEX 문
- Q1~Q3 답변
*/

-- [코드 작성란]
--1.
select min(price) 
from products;
--min(price)= 100
select max(price) 
from products;
--max(price)= 4999

--2.
drop index if exists idx_products_price;
--현재 없는 상태

--3.
explain analyze
select price
from products
where price >= 100 AND price < 120;

/*
 *4.
 *스캔 방식: Seq Scan on products
 *cost: 0.00 / 205.00 
 *actual rows: 35.00
 *Execution Time: 0.013 / 0.313
 */

--5.
create index idx_products_price 
on products(price);

--6.
explain analyze
select price
from products
where price >= 100 AND price < 120;

/*
 * 7.
 * 스캔 방식: Index Only Scan using idx_products_price on products
 * cost: 0.29 / 5.12
 * actual rows: 35.00
 * Execution Time: 0.003 / 0.004 
 */

/*
 * 8.
 * 인덱스 생성 후 스캔 방식이 full scan 형태에서 Index only Scan 으로 바뀌었다.
 * Index Only Scan 으로 바뀐 뒤 cost 가 약 205에서 약 5로 크게 감소하였다.
 * actual rows는 전후 동일하다.
 * Index Only Scan 으로 바뀐 뒤 Execution Time이 약 0.313에서 0.004로
 * 크게 감소하였다.
 */

--9.
drop index if exists idx_products_price;
--삭제하였음.

/*
 * 10.
 * Q1. 
 * >, <, >=, <= 등등
 * 
 * Q2.
 * Full Scan 방식에서 Index Only Scan 방식을 사용할 수 있게 되어
 * 탐색 범위가 크게 줄어든다. 해당 Index 근처로 빠르게 갈 수 있기 때문이다.
 * 
 * Q3. 
 * 중첩 쓰기 비용이 발생하기 때문이다. 또한 Index가 변경되는 과정에서 
 * 인덱스 테이블에 빈 공간이나 페이지 분할이 발생하기 때문이다. 
 * 다만, 이는 코드를 통해 어느 정도 해결 가능하긴 하다.  
 */

/*
============================================================
실습 마무리
============================================================

1. B-Tree 인덱스가 검색 속도를 높일 수 있는 핵심 원리는 무엇인가요?
데이터가 인덱스를 기준으로 정렬된 상태가 되기 때문에 모든 데이터를 다 살펴볼 필요가 없어져
검색 속도가 빨라진다.

2. B-Tree 인덱스는 등호 검색과 범위 검색에서 각각 어떻게 활용될 수 있나요?
등호 검색: 해당 값의 인덱스로 바로 이동하여 검색할 수 있다.
범위 검색: 해당 범위의 시작점으로 가서 검색을 시작할 수 있다.

3. 인덱스를 만들 때 조회 성능뿐 아니라 쓰기 성능도 고려해야 하는 이유는 무엇인가요?
인덱스가 생길수록 조회 성능은 올라가지만, 데이터가 변경될 때 인덱스도 같이 변경해줘야 하므로
쓰기 성능은 내려가게 된다. 
따라서 일반적으로 조회 성능과 쓰기 성능은 trade-off 관계에 놓여 있다.
*/
