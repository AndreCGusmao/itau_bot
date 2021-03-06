class ItauWebScraper
  include Capybara::DSL

  def initialize
    page.driver.headers = { 'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1916.153 Safari/537.36" }
    visit "/"

    @payload = {}
    @credentials = ItauWebCredentials.from_env
  end

  def login
    puts "-----> Login"

    fill_in "campo_agencia", with: @credentials.agencia
    fill_in "campo_conta", with: @credentials.conta
    click_on "Acessar"

    click_on @credentials.nome

    puts "-----> Password"
    @credentials.senha.chars.each do |char|
      find(".TextoTecladoVar img[title*='#{char}']").click
    end

    find("img[alt='Continuar']").click

    @logged_in = true
  end

  def scrape_balance
    login unless @logged_in
    puts "-----> Balance"

    click_on "ver extrato"
    select "ltimos 90 dias", from: "periodoExtrato"
    sleep 9 # required for this ^

    @payload.merge!({ main_account_id => ItauBalanceParser.new.parse(page.html) })
  end

  def scrape_savings
    login unless @logged_in
    puts "-----> Savings"

    click_on "Poupança"
    click_on "30 dias"
    find("#poupanca1").click
    click_on "CONTINUAR"

    @payload.merge!({ savings_account_id => ItauSavingsParser.new.parse(page.html) })
  end

  def scrape
    scrape_balance rescue nil
    scrape_savings rescue nil

    @payload
  end

  def main_account_id
    ENV['GRANAIO_ITAU_MAIN_ACCOUNT'] || 'balance'
  end

  def savings_account_id
    ENV['GRANAIO_ITAU_SAVINGS_ACCOUNT'] || 'savings'
  end
end
