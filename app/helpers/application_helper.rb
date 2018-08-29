module ApplicationHelper
	# 指定の数値ｇがマイナスの場合は特定のタグを付与する
	# number: 対象の数値。数値型である必要がある
	# type: currency (通貨","をつける)
	def minus_number_tag(number, type = nil)
		if type == 'currency'
			str = number_to_currency(number, unit:'', precision: 0, format: '%n %u')
		else
			str = number.to_s
		end

		if number < 0
			str = content_tag(:span, str, class: 'minus_number')
		end

		return str
	end
end
