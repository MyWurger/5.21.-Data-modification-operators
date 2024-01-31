-- Задача 1. Создайте таблицу EMP(employee_id, first_name , last_name ,hire_date, rating_e, working, layer) и заполните данными о сотрудниках, работающих в отделе 80. Столбцу working присвоить значение, равное количеству полных лет, которые проработал сотрудник. А значение столбца layer зависит от значения столбца rating_e. Если rating_e равен 5 то layer= ‘A’, если rating_e равен 4 или 3 то layer= ‘B’, у остальных сотрудников layer= ‘C’.

create table EMP
( employee_id int,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  hire_date DATE,
  rating_e INT,
  working int,
  layer CHAR(1)
)

INSERT INTO EMP (employee_id, first_name, last_name, hire_date, rating_e, working, layer)
SELECT employee_id, first_name, last_name, hire_date, rat-ing_e,
EXTRACT('year' from AGE(CURRENT_DATE, hire_date)),
CASE
   WHEN rating_e = 5 THEN 'A'
   WHEN rating_e IN (4, 3) THEN 'B'
   ELSE 'C'
END AS layer
FROM employees
WHERE department_id = 80
returning *;


-- Задача 2. Увеличить на 1 rating_e сотрудников, которые осуществили продажи на сумму более 1000000 и имеют rating_e < 5

update emp
set rating_e = rating_e + 1
where employee_id in (
  select e.employee_id
  from emp e
  join orders o on (e.employee_id = o.salesman_id)
  join order_items oi using (order_id)
  group by e.employee_id
  having sum(oi.quantity * oi.unit_price) > 1000000
)
and rating_e < 5
returning *;


-- Задача 3. Добавить в таблицу Employees_Copy столбец emp_sales и присвоить ему значение общей стоимости продаж осуществленных каждым сотрудником.

CREATE TABLE Employees_Copy AS
SELECT employee_id, first_name, last_name, hire_date, NULL as emp_sales
FROM employees;

UPDATE Employees_Copy e
SET emp_sales = (
  SELECT SUM(quantity * unit_price)
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.salesman_id = e.employee_id
)
returning *;


-- Задача 4. Выполните слияние таблицы Orders1 только с теми строками таблицы Orders2, в которых заказы находятся в состоянии 'Shipped'.

merge into only orders1
using orders2
on orders1.order_id  = orders2.order_id 
when matched and orders2.status = 'Shipped' then
 update set status = orders2.status
when not matched and orders2.status = 'Shipped' then 
 insert (order_id,customer_id,status,salesman_id,order_date)
val-ues(orders2.order_id,orders2.customer_id,orders2.status,orders2.salesman_id,orders2.order_date );


-- Задача 5. Создайте таблицу Order_Items_New, которая содержит данные о но-вых продажах, и заполните ее данными. Выполните слияние таблицы Order_Items_Copy с таблицей Order_Items_New. Алгоритм слияния: если в таб-лице Order_Items_Copy существует строка, у которой значения столбцов order_id, product_id совпадают со значениями этих столбцов в добавляемой строке из таблицы Order_Items_New, то обновить значение столбца quantity, в противном случае вставить новую строку.

CREATE TABLE  Order_Items_Copy AS
SELECT * FROM order_items;

CREATE TABLE Order_Items_New (
  order_id INT,
  item_id INT,
  product_id INT,
  quantity INT,
  unit_price DECIMAL(10,2)
);

insert into Order_Items_New (order_id, item_id, product_id, quantity, unit_price)
VALUES
  (87, 9, 1, 46, 620.00),
  (200, 73, 102, 50, 1000.00),
  (30, 1, 35, 1, 6000.00),
  (12, 4, 13, 2, 1200.99),
  (69, 6, 69, 39, 799.00),
  (500, 5, 120, 8, 999.00),
  (78, 11, 23, 20, 1099.00),
  (43, 5, 1, 100, 3000.00),
  (90, 3, 5, 63, 1532.00),
  (102, 2, 11, 4, 2300.00);

MERGE INTO Order_Items_Copy AS t
USING Order_Items_New AS s
ON (t.order_id = s.order_id AND t.product_id = s.product_id)
WHEN MATCHED THEN
  UPDATE SET quantity = s.quantity
WHEN NOT MATCHED THEN
  INSERT (order_id, item_id, product_id, quantity, unit_price) 
  VALUES (s.order_id, s.item_id, s.product_id, s.quantity, s.unit_price);
 
SELECT * FROM Order_Items_Copy;


-- Задача 6. Удалить данные об отмененных заказах (status = ‘Canceled’), с даты оформления которых прошло более 5 лет.

CREATE TABLE Order_copy AS
SELECT * FROM orders;

DELETE FROM Order_copy
WHERE status = 'Canceled' AND order_date < CURRENT_DATE - IN-TERVAL '5 years'
RETURNING *;


-- Задача 7. Удалить из таблицы Order_Items_Copy данные о продаже товаров, которые нарушают правило: рейтинг продавца должен больше или равен рейтингу товара.

CREATE TABLE  Order_Items_Copy AS
SELECT * FROM order_items;

delete from Order_Items_Copy
where product_id in
(select product_id
 from order_items_copy oic join products p using (product_id)
 join orders o using (order_id)
 join employees e on (e.employee_id = o.salesman_id)
 -- выбираем столбцы, где рейтинг товара больше рейтинга про-давца - они удаляются
 where e.rating_e < p.rating_p and o.salesman_id is not null
)
returning *;

