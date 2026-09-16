/*
============================================================
과제. 주문-배송 복합 데이터셋 구성 및 결과 검증
============================================================

[문제 3-1] 모든 주문을 유지하면서 배송 정보 결합하기

[문제 설명]
물류 운영팀에서 모든 주문을 기준으로 배송 정보를 함께 확인하려고 합니다.

배송 정보가 없는 주문도 결과에서 사라지면 안 되므로,
적절한 JOIN 종류를 선택해야 합니다.

또한 조인 후 주문 수가 의도와 맞는지 검증해야 합니다.

※ 과제는 필수 문제와 동일한 수준입니다.
   이번 강에서 배운 JOIN 종류 선택과 결과 검증을 스스로 적용하는 문제입니다.

[요구사항]
1. orders를 기준 테이블로 사용하세요.
2. customers를 customer_id 기준으로 JOIN하세요.
3. shipments를 order_id 기준으로 연결하되,
   배송 정보가 없는 주문도 유지되도록 적절한 JOIN 종류를 사용하세요.
4. 다음 컬럼을 조회하세요.
   - orders.order_id
   - orders.order_date
   - customers.customer_id
   - customers.city
   - shipments.shipment_id
   - shipments.status
5. orders 전체 행 수를 확인하세요.
6. 최종 조인 결과의 전체 행 수를 확인하세요.
7. shipment_id가 NULL인 주문 수를 확인하세요.
8. order_id별 행 수를 GROUP BY하고,
   2행 이상 나타나는 주문이 있는지 확인하세요.
9. 다음 질문에 답하세요.
   Q1. shipments를 INNER JOIN이 아니라 LEFT JOIN으로 연결해야 하는 이유는 무엇인가요?
   Q2. shipment_id가 NULL인 행은 어떤 의미인가요?
   Q3. 조인 후 행 수가 orders보다 많아졌다면 어떤 관계나 데이터를 먼저 점검해야 하나요?
   Q4. 조인 결과 검증을 위해 행 수, 중복, NULL을 함께 확인해야 하는 이유는 무엇인가요?
   Q5. LEFT JOIN한 shipments의 status 조건을
       ON 절에 작성하는 경우와 WHERE 절에 작성하는 경우
       결과가 어떻게 달라질 수 있나요?

[제출 결과]
- 다단계 JOIN SQL
- orders 행 수
- 조인 후 행 수
- 배송 정보 없는 주문 수
- order_id 중복 검증
- Q1~Q5 답변
*/

-- [코드 작성란]
-- [코드 작성란]

-- 1~4. 다단계 JOIN
select
    o.order_id,
    o.order_date,
    c.customer_id,
    c.city,
    s.shipment_id,
    s.status
from orders o
join customers c on o.customer_id = c.customer_id
left join shipments s on o.order_id = s.order_id;

-- 5. orders 전체 행 수
select count(*) 
from orders;

-- 6. 최종 조인 결과 전체 행 수
select count(*) 
from orders o
join customers c on o.customer_id = c.customer_id
left join shipments s on o.order_id = s.order_id;

-- 7. shipment_id가 NULL인 주문 수
select count(*) 
from orders o
join customers c on o.customer_id = c.customer_id
left join shipments s on o.order_id = s.order_id
where s.shipment_id is null;

-- 8. order_id별 행 수 확인 (2행 이상인 주문 존재 여부)
select
    o.order_id,
    count(*) 
from orders o
join customers c on o.customer_id = c.customer_id
left join shipments s on o.order_id = s.order_id
group by o.order_id
having count(*) >= 2;



/*
============================================================
실습 마무리
============================================================

아래 내용을 한 문단으로 정리하세요.

1. 다단계 조인을 작성할 때 가장 먼저 확인해야 하는 것은 무엇인가요?
테이블 간의 연결 관계.

2. 1:N 관계에서 행 수가 증가하는 이유는 무엇인가요?
일대다 관계이므로 하나의 행에 여러 개의 행이 결합되기 때문이다.

3. LEFT JOIN에서 오른쪽 테이블 조건을 ON과 WHERE에 둘 때 결과가 달라지는 이유는 무엇인가요?
on절에 조건을 쓸 경우에는 어떤 식으로 join을 할지를 정해줄 뿐이고,
where절에 조건을 쓸 경우에는 조건에 해당하지 않거나, null인 것들을 포함시키지 않기 때문이다.

4. 조인 결과를 검증할 때 어떤 항목을 확인해야 하나요?
각 테이블의 기존 행 수와 조인한 테이블의 행 수 비교를 통해 두 테이블이 어떤 관계인지 확인 가능.
null 값이 포함된 행 수를 확인.

*/
