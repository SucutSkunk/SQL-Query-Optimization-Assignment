/*
============================================================
과제. 여러 단계 분석을 CTE로 구조화하기
============================================================

[문제 3-1] 우수 고객의 도시별 구매금액 집계

[문제 설명]
운영팀에서 고객별 구매금액을 계산한 뒤,
총 구매금액이 50,000 이상인 우수 고객만 추려
도시별 우수 고객 수와 구매금액을 집계하려고 합니다.

이번 문제에서는 여러 단계의 로직을 CTE로 나누어
쿼리의 흐름을 명확하게 표현하세요.

※ 과제는 필수 문제와 동일한 수준입니다.
   새로운 SQL 문법을 사용하는 것이 아니라,
   이번 강에서 배운 CTE 구조화를 한 번 더 적용하는 문제입니다.

[요구사항]
1. 첫 번째 CTE customer_totals를 작성하세요.
   - orders와 order_items를 order_id 기준으로 JOIN
   - customer_id별 총 구매금액 계산
   - 총 구매금액 컬럼명은 total_amount
2. 두 번째 CTE high_value_customers를 작성하세요.
   - customer_totals에서 total_amount가 50,000 이상인 고객만 선택
3. high_value_customers와 customers를 customer_id 기준으로 JOIN하세요.
4. 도시별로 다음 값을 계산하세요.
   - 우수 고객 수: vip_customer_count
   - 우수 고객 총 구매금액: vip_total_amount
5. vip_total_amount가 높은 순서대로 정렬하세요.
6. 작성한 전체 CTE 쿼리에 EXPLAIN을 적용하여 실행계획을 확인하세요.
7. 실행계획에서 CTE가 본문에 인라인된 형태인지,
   별도의 CTE Scan이 나타나는지 확인하세요.
8. 다음 질문에 답하세요.
   Q1. 이 문제를 하나의 중첩 서브쿼리로 작성하는 것보다 CTE로 나누었을 때 어떤 장점이 있나요?
   Q2. customer_totals와 high_value_customers라는 이름은 각각 어떤 처리 단계를 의미하나요?
   Q3. 성능 차이가 거의 없다면 CTE와 중첩 서브쿼리 중 어떤 기준으로 구조를 선택하는 것이 좋나요?
   Q4. 이번 EXPLAIN 결과를 기준으로 CTE가 실제 실행 단계에서
       반드시 별도의 중간 결과로 저장되었다고 말할 수 있나요?
       실행계획을 근거로 설명하세요.

[제출 결과]
- 전체 CTE SQL
- 도시별 집계 결과
- EXPLAIN 실행계획
- CTE 인라인 또는 CTE Scan 여부 확인
- Q1~Q4 답변
*/

-- [코드 작성란]
-- 1~5. CTE로 단계별 구조화
with customer_totals as (
    select
        o.customer_id,
        sum(oi.qty * oi.price) as total_amount
    from orders o
    join order_items oi on o.order_id = oi.order_id
    group by o.customer_id
),
high_value_customers as (
    select
        customer_id,
        total_amount
    from customer_totals
    where total_amount >= 50000
)
select
    c.city,
    count(hvc.customer_id) as vip_customer_count,
    sum(hvc.total_amount) as vip_total_amount
from high_value_customers hvc
join customers c on hvc.customer_id = c.customer_id
group by c.city
order by vip_total_amount desc;

-- 6. EXPLAIN 적용
explain
with customer_totals as (
    select
        o.customer_id,
        sum(oi.qty * oi.price) as total_amount
    from orders o
    join order_items oi on o.order_id = oi.order_id
    group by o.customer_id
),
high_value_customers as (
    select
        customer_id,
        total_amount
    from customer_totals
    where total_amount >= 50000
)
select
    c.city,
    count(hvc.customer_id) as vip_customer_count,
    sum(hvc.total_amount) as vip_total_amount
from high_value_customers hvc
join customers c on hvc.customer_id = c.customer_id
group by c.city
order by vip_total_amount desc;

/*
 * 7.
 * CTE Scan이 나타나지 않으므로 
 * CTE가 본문에 인라인된 형태이다. 
 */

/*
 * 8.
 * Q1.
 * 실제 실행 시간에는 큰 차이가 없을지 몰라도 
 * CTE 방식은 가독성이 중첩 쿼리문 보다 가독성이 뛰어나다.
 * 
 * Q2.
 * customer_totals: orders와 order_items를 조인해서 고객별 총 구매금액을 집계하는 단계
 * high_value_customers: 그 집계 결과에서 total_amount가 50,000 이상인 고객만 걸러내는 단계
 * 
 * Q3.
 * 성능 차이가 별로 없다면 CTE를 쓰는 것이 좋다.
 * 가독성이 뛰어나고, 다른 사람과 협업할 때도 좋다.
 * 
 * Q4. 
 * 저장되었다고 확신할 수 없다.
 * CTE Scan 이 실행계획에 등장하지 않았기 때문이다.
 * 만약 확실히 중간 결과로 저장하고 싶다면, materialized를 as 뒤에 삽입하면 된다.
 */


/*
============================================================
실습 마무리
============================================================

아래 내용을 한 문단으로 정리하세요.

1. CTE와 중첩 서브쿼리의 가장 큰 구조적 차이는 무엇인가요?
CTE는 서브쿼리 보다 가독성이 훨씬 뛰어나다.

2. 일반 CTE와 MATERIALIZED CTE의 처리 방식은 어떻게 다를 수 있나요?
3. 실행계획상 성능 차이가 크지 않다면 어떤 기준으로 쿼리 구조를 선택하는 것이 좋나요?
*/
