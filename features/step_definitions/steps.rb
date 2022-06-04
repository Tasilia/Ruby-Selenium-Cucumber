=begin
Цыганкова Анастасия
Тестовое задание для IChooseAlfa
Расчет ежемесячного платежа на сайте https://calcus.ru/kalkulyator-ipoteki
=end

require 'selenium-webdriver'
service = Selenium::WebDriver::Service.chrome(path: './chromedriver.exe')
Driver = Selenium::WebDriver.for :chrome, service: service

#Метод для генерации случайного числа от 5 до 12 вкл.
def random_rate
	rate = rand(5..12)
	return rate
end
#Словарь для хранения относительных путей
Path = {'Заголовок "Ипотечный калькулятор"'=>"//h1[text()='Ипотечный калькулятор']",
	'Ссылка "По стоимости недвижимости"'=>"//a[@data-autofocus = 'cost']",
	'Ссылка "По сумме кредита"'=>"//a[@data-autofocus = 'credit_sum']",
	'Текст "Стоимость недвижимости"'=>"//div[text()='Стоимость недвижимости']",
	'Текст "Первоначальный взнос"'=>"//div[text()='Первоначальный взнос']",
	'Текст "Сумма кредита"'=>"//div[text()='Сумма кредита']",
	'Текст "Срок кредита"'=>"//div[text()='Срок кредита']",
	'Текст "Процентная ставка"'=>"//div[@class='calc-frow']//div[@class='calc-fleft']",
	'Текст "Тип ежемесячных платежей"'=>"//div[@class='calc-frow calc_type-x calc_type-1']//div[@class='calc-fleft']",
	'поле "Стоимость недвижимости"'=>'//input[@name="cost"]',
	'выпадающий список'=>"//select[@name='start_sum_type']/option[2]",
	'поле "Первоначальный взнос"'=>'//input[@name="start_sum"]',
	"Первоначальный взнос"=>'//div[@class="calc-input-desc start_sum_equiv"][text()="(2 400 000 руб.)"]',
	"Сумма кредита"=>'//span[@class="credit_sum_value text-muted"][text()="9 600 000"]',
	'поле "Срок кредита"'=>'//input[@name="period"]',
	'поле "Процентная вставка"'=>'//input[@name="percent"]',
	'Аннуитетные'=>'//input[@name="payment_type"][@value="1"]',
	'Дифференцированные'=>'//input[@name="payment_type"][@value="2"]',
	'Рассчитать'=>"//input[@value='Рассчитать']"
	}

Given('открыт сайт calcus.ru\/kalkulyator-ipoteki') do
	Driver.get("https://calcus.ru/kalkulyator-ipoteki")
end

When('{string} присутствует на странице') do |string|
	Driver.find_element(:xpath, Path[string])
end

Then('{string} отображается на странице') do |string|
	if Driver.find_element(:xpath, Path[string]).displayed? == FALSE
		raise StandardError, "#{string} не отображается на странице"
	end
end

When('в {string} ввести значение {int}') do |string, int|
	Driver.find_element(:xpath, Path[string]).send_keys int
	#выводим значение int для дальнейшего расчёта
	case string
	when 'поле "Стоимость недвижимости"'
		Cost = int
	when 'поле "Первоначальный взнос"'
		FirstPayment = int
	when 'поле "Срок кредита"'
		Years = int
	end
end

When('в элементе {string} рядом с полем «Первоначальный взнос» выбрать значение %') do |string|
  	Driver.find_element(:xpath, Path[string]).click
end

When('в разделе {string} появилось значение {int} руб.') do |string, int|
	if Driver.find_element(:xpath, Path[string]).displayed? == FALSE
		raise StandardError, "в разделе #{string} не появилось значение #{int} руб."
	end
end

When('в {string} ввести сгенерированное случайное число в диапазоне от {int} до {int} включительно') do |string, int1, int2|
	Rate = random_rate
	Driver.find_element(:xpath, Path[string]).send_keys Rate
end

When('радиобаттон {string} отмечен') do |string|
  	if Driver.find_element(:xpath, Path[string]).selected? == FALSE
  		raise StandardError, "Радиобаттон 'Аннуитетные' не отмечен"
  	end
end

When('радиобаттон {string} не отмечен') do |string|
 	if Driver.find_element(:xpath, Path[string]).selected?
  		raise StandardError, "Радиобаттон 'Дифференцированные' отмечен"
  	end 
end

When('нажать на кнопку {string}') do |string|
  	Driver.find_element(:xpath, Path[string]).click
  	sleep 5
end

Then('значение ежемесячного платежа совпадает со значением, рассчитанным по формуле') do
  	search_monthlyPayment = Driver.find_element(:xpath, '//div[@class="calc-result-value result-placeholder-monthlyPayment"]').text
	Driver.quit
	#приводим полученное значение ежемесячного платежа к типу float
	monthly_payment=search_monthlyPayment.delete " "
	monthly_payment=monthly_payment.sub(",",".").to_f
	credit = Cost*(1-FirstPayment.to_f/100) #сумма кредита
	rate_in_month = Rate.to_f/100/12 #процентная ставка в месяц
	months = Years*12 #кол-во месяцев
	#рассчитанный ежемесячный платеж по формуле
	monthly_payment_calc = credit*rate_in_month*((1+rate_in_month)**months)/(((1+rate_in_month)**months)-1)
	monthly_payment_calc = monthly_payment_calc.round(2)
	if monthly_payment_calc != monthly_payment
		raise StandardError, "Ежемесячный платёж не совпадает со значением, рассчитанным по формуле"
	end
end