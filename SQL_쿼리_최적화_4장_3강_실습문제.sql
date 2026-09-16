/*
============================================================
[4장 3강] 실습문제: 누적합과 이전 행 비교
============================================================

[실습 목표]
- SUM() OVER를 이용하여 날짜 기준 누적합을 계산할 수 있다.
- ROWS BETWEEN을 이용하여 이동평균 계산 범위를 지정할 수 있다.
- LAG와 LEAD를 이용하여 이전 행과 다음 행의 값을 참조할 수 있다.
- 전일 대비 증감액과 증감률을 계산할 수 있다.
- 계산 결과를 매출 흐름 관점에서 해석할 수 있다.

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

[주요 관계]
- orders.order_id = order_items.order_id

[주요 컬럼]
orders
- order_id
- order_date
- customer_id
- store_id

order_items
- order_item_id
- order_id
- product_id
- qty
- price

[주의사항]
- 일별 매출은 SUM(order_items.qty * order_items.price)로 계산합니다.
- 먼저 날짜별 매출을 집계한 뒤 윈도우 함수를 적용합니다.
- LAG/LEAD는 ORDER BY 순서상 이전/다음 행을 참조합니다.
*/

/*
============================================================
과제. 누적매출과 전일 대비 증감률 분석
============================================================

[문제 3-1] 일별 매출 변화 리포트 만들기

[문제 설명]
운영 리포트에서 다음 정보를 한 번에 확인하려고 합니다.

- 일별 매출
- 해당 날짜까지 누적 매출
- 전일 매출
- 전일 대비 증감액
- 전일 대비 증감률

이번 강에서 배운 SUM() OVER와 LAG를 함께 사용하여
일별 매출 변화 리포트를 작성하세요.

※ 과제는 필수 문제와 동일한 수준입니다.

[요구사항]
1. orders와 order_items를 order_id로 JOIN하세요.
2. order_date별 daily_sales를 계산하세요.
3. daily_sales_summary CTE를 작성하세요.
4. 다음 값을 계산하세요.
   - running_total
   - prev_day_sales
   - day_over_day_diff
   - day_over_day_pct
5. 전일 대비 증감률은 다음 식을 사용하세요.

   (현재 매출 - 전일 매출) / 전일 매출 * 100

6. 전일 매출이 0인 경우 오류가 발생하지 않도록 NULLIF를 사용하세요.
7. 증감률은 ROUND(..., 2)를 이용해 소수 둘째 자리까지 표시하세요.
8. 결과를 order_date 오름차순으로 정렬하세요.
9. day_over_day_pct가 음수인 날짜만 별도로 조회하세요.
10. 다음 질문에 답하세요.
    Q1. 첫 번째 날짜의 증감률이 NULL이 되는 이유는 무엇인가요?
    Q2. NULLIF(prev_day_sales, 0)를 사용하는 이유는 무엇인가요?
    Q3. day_over_day_pct가 음수라는 것은 비즈니스적으로 무엇을 의미하나요?
    Q4. 하루의 감소만으로 매출 추세가 악화되었다고 단정하기 어려운 이유는 무엇인가요?

[제출 결과]
- 전체 일별 매출 변화 SQL
- 매출 감소 날짜 조회 SQL
- Q1~Q4 답변
*/

-- [코드 작성란]
WITH daily_sales AS (
    SELECT
        o.order_date,
        SUM(oi.qty * oi.price) AS daily_sales
    FROM orders o
    JOIN order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.order_date
),
daily_sales_summary AS (
    SELECT
        order_date,
        daily_sales,
        SUM(daily_sales) OVER (
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,
        LAG(daily_sales) OVER (
            ORDER BY order_date
        ) AS prev_day_sales
    FROM daily_sales
)
SELECT
    order_date,
    daily_sales,
    running_total,
    prev_day_sales,
    daily_sales - prev_day_sales AS day_over_day_diff,
    ROUND(
        (daily_sales - prev_day_sales) / NULLIF(prev_day_sales, 0) * 100,
        2
    ) AS day_over_day_pct
FROM daily_sales_summary
ORDER BY order_date;

WITH daily_sales AS (
    SELECT
        o.order_date,
        SUM(oi.qty * oi.price) AS daily_sales
    FROM orders o
    JOIN order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.order_date
),
daily_sales_summary AS (
    SELECT
        order_date,
        daily_sales,
        SUM(daily_sales) OVER (
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,
        LAG(daily_sales) OVER (
            ORDER BY order_date
        ) AS prev_day_sales
    FROM daily_sales
),
sales_report AS (
    SELECT
        order_date,
        daily_sales,
        running_total,
        prev_day_sales,
        daily_sales - prev_day_sales AS day_over_day_diff,
        ROUND(
            (daily_sales - prev_day_sales) / NULLIF(prev_day_sales, 0) * 100,
            2
        ) AS day_over_day_pct
    FROM daily_sales_summary
)
SELECT *
FROM sales_report
WHERE day_over_day_pct < 0
ORDER BY order_date;

/*
 * Q1.
 * ORDER BY order_date 기준 가장 첫 번째 행에는 LAG가 가져올 이전 행이 존재하지 않아 prev_day_sales가 NULL이 되고, 
 * NULL을 포함한 산술 연산 결과도 모두 NULL이 되어 day_over_day_pct 역시 NULL이 됩니다.
 * 
 * Q2.
 * 특정 날짜의 전일 매출이 0이면 증감률 계산의 분모가 0이 되어 division by zero 오류가 발생합니다. 
 * NULLIF(prev_day_sales, 0)은 분모가 0일 때 이를 NULL로 바꿔줘서, 오류 대신 결과값이 NULL로 안전하게 처리되도록 합니다.
 * 
 * Q3.
 * 전일 대비 매출이 감소했다는 뜻으로, 해당 날짜의 매출 흐름이 둔화되거나 하락하는 신호로 해석할 수 있습니다.
 * 
 * Q4.
 * 매출은 요일 효과, 프로모션 종료, 특정 이벤트, 랜덤 변동 등 다양한 단기 요인으로 하루 단위로도 등락할 수 있기 때문에, 
 * 단 하루의 감소만 보고 전체 추세가 악화되었다고 판단하기는 어렵습니다. 여러 날에 걸친 흐름이나 이동평균 같은 지표를 함께 봐야 추세를 더 정확히 판단할 수 있습니다.

/*
============================================================
실습 마무리
============================================================

아래 내용을 한 문단으로 정리하세요.

1. 누적합과 이동평균의 계산 범위는 어떻게 다른가요?
2. LAG와 LEAD는 각각 어떤 행을 참조하나요?
3. 전일 대비 증감률 계산에서 NULLIF가 필요한 이유는 무엇인가요?
4. 윈도우 함수 결과를 비즈니스 지표로 해석할 때 무엇을 주의해야 하나요?

누적합은 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW처럼 파티션의 첫 행부터 현재 행까지 전체를 계속 더해 나가는 반면 
이동평균은 ROWS BETWEEN N PRECEDING AND CURRENT ROW처럼 현재 행 주변의 정해진 범위(최근 N개 행)만을 계산에 사용한다는 점에서 계산 범위가 다르고, 
LAG는 ORDER BY로 정렬된 결과에서 현재 행보다 앞선 이전 행의 값을, LEAD는 현재 행보다 뒤에 있는 다음 행의 값을 가져오며, 
전일 대비 증감률을 계산할 때 전일 매출이 0인 경우 나누기 오류가 발생할 수 있으므로 NULLIF(prev_day_sales, 0)으로 분모를 안전하게 처리해야 하고, 

마지막으로 윈도우 함수로 계산한 지표를 비즈니스적으로 해석할 때는 단 하루·한 시점의 변동만으로 전체 추세를 단정하지 말고 
요일 효과나 이벤트 같은 단기 변동 요인과 여러 기간에 걸친 흐름을 함께 고려해야 한다.
*/
