/*
============================================================
[4장 2강] 실습문제: 순위 산출과 그룹 내 비교 함수
============================================================

[실습 목표]
- ROW_NUMBER, RANK, DENSE_RANK의 동점 처리 차이를 설명할 수 있다.
- PARTITION BY를 이용하여 그룹별 순위를 계산할 수 있다.
- 그룹별 상위 N개 데이터를 추출할 수 있다.
- NTILE을 이용하여 데이터를 균등한 그룹으로 나눌 수 있다.
- 순위와 그룹 결과를 비즈니스 지표 관점에서 해석할 수 있다.

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
- products
- orders
- customers

[주요 관계]
- order_items.product_id = products.product_id
- orders.order_id = order_items.order_id
- orders.customer_id = customers.customer_id

[주의사항]
- 현재 데이터셋의 order_items 판매 수량 컬럼은 qty입니다.
- 구매금액은 qty * price로 계산합니다.
- 순위 함수 결과를 WHERE에서 바로 필터링할 수 없으므로
  그룹별 상위 N개를 추출할 때는 서브쿼리 또는 CTE를 사용합니다.
*/

/*
============================================================
과제. NTILE을 이용한 고객 구매등급 분류
============================================================

[문제 3-1] 고객을 구매금액 기준 4개 그룹으로 나누기

[문제 설명]
마케팅팀에서 고객별 총 구매금액을 기준으로
고객을 4개 그룹으로 나누려고 합니다.

구매금액이 높은 고객부터 정렬하고
NTILE(4)를 이용하여 전체 고객 수를 최대한 균등하게 4개 그룹으로 나누세요.

※ 과제는 필수 문제와 동일한 수준입니다.

[요구사항]
1. orders와 order_items를 order_id 기준으로 JOIN하세요.
2. 고객별 총 구매금액을 SUM(qty * price)로 계산하세요.
3. 총 구매금액 컬럼명은 total_amount로 지정하세요.
4. NTILE(4)를 이용하여 구매금액이 높은 고객부터
   customer_group 1~4를 부여하세요.
5. 결과는 customer_group 오름차순,
   total_amount 내림차순으로 정렬하세요.
6. 각 customer_group별 고객 수를 확인하세요.
7. 각 customer_group별 평균 구매금액을 계산하세요.
8. 다음 질문에 답하세요.
   Q1. NTILE(4)는 금액 범위를 정확히 4등분하나요,
       아니면 고객 수를 기준으로 최대한 균등하게 나누나요?
   Q2. customer_group = 1은 어떤 고객군으로 해석할 수 있나요?
   Q3. 이 결과를 마케팅 업무에 어떻게 활용할 수 있나요?

[제출 결과]
- 고객별 총 구매금액 CTE
- NTILE(4) 적용 SQL
- 그룹별 고객 수
- 그룹별 평균 구매금액
- Q1~Q3 답변
*/

-- [코드 작성란]
--1~5.
WITH customer_totals AS (
    SELECT
        o.customer_id,
        SUM(oi.qty * oi.price) AS total_amount
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_amount,
    NTILE(4) OVER (
        ORDER BY total_amount DESC
    ) AS customer_group
FROM customer_totals
ORDER BY
    customer_group ASC,
    total_amount DESC;

--6~7.
WITH customer_totals AS (
    SELECT
        o.customer_id,
        SUM(oi.qty * oi.price) AS total_amount
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
customer_groups AS (
    SELECT
        customer_id,
        total_amount,
        NTILE(4) OVER (ORDER BY total_amount DESC) AS customer_group
    FROM customer_totals
)
SELECT
    customer_group,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_amount), 2) AS avg_amount
FROM customer_groups
GROUP BY customer_group
ORDER BY customer_group;

/*
 * 8.
 * Q1.
 * 고객 수를 기준으로 최대한 균등하게 나눕니다. 
 * Q2.
 * total_amount DESC 정렬 기준으로 나눴으므로, customer_group = 1은 구매금액 상위 25%에 해당하는, 
 * 가장 많이 구매한 우수(VIP) 고객 그룹으로 해석할 수 있습니다.
 * Q3.
 * 1등급 고객에게는 VIP 혜택·감사 쿠폰 등 리텐션 캠페인을, 
 * 하위 등급(3~4등급)에게는 재구매 유도 프로모션이나 할인 쿠폰을 보내는 등 등급별 차등 마케팅 전략의 타깃 리스트로 바로 활용할 수 있습니다.
 */

/*
============================================================
실습 마무리
============================================================

아래 내용을 한 문단으로 정리하세요.

1. ROW_NUMBER, RANK, DENSE_RANK의 가장 큰 차이는 무엇인가요?
2. PARTITION BY를 순위 함수와 함께 사용하면 무엇이 달라지나요?
3. 그룹별 상위 N개를 추출할 때 서브쿼리나 CTE가 필요한 이유는 무엇인가요?
4. NTILE 결과를 비즈니스 지표로 해석할 때 주의해야 할 점은 무엇인가요?

ROW_NUMBER, RANK, DENSE_RANK의 가장 큰 차이는 동점 처리 방식에 있는데, 
ROW_NUMBER는 동점이어도 무조건 순차 번호(1, 2, 3…)를 부여하고 
RANK는 동점에 같은 순위를 준 뒤 동점자 수만큼 다음 순위를 건너뛰며(1, 2, 2, 4) 
DENSE_RANK는 동점에 같은 순위를 주되 다음 순위를 건너뛰지 않는다(1, 2, 2, 3); 
이때 PARTITION BY를 순위 함수와 함께 사용하면 전체 데이터 전체가 아니라 
지정한 그룹(카테고리, 매장, 고객 등) 단위로 순위가 다시 1부터 매겨지고, 
순위 함수는 SELECT 절에서만 계산되어 WHERE에서 바로 조건을 걸 수 없기 때문에 
그룹별 상위 N개를 뽑으려면 서브쿼리나 CTE로 한 번 감싼 뒤 바깥 쿼리에서 필터링해야 하며, 
NTILE은 금액 등 지표의 절대적인 구간을 나누는 것이 아니라 정렬된 행의 개수를 균등하게 분할하는 것이므로 
그룹 간 실제 금액 격차가 크게 다를 수 있다는 점에 유의해서 비즈니스적으로 해석해야 한다.
*/
