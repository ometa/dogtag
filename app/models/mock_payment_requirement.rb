class MockPaymentRequirement < PaymentRequirement
  # Mock payment requirement for testing - doesn't connect to Stripe
  # Always mocks successful payment

  def stripe_params(team)
    # Return mock params that won't connect to Stripe
    {
      description: "MOCK: #{name} for #{team.name}",
      amount: active_tier.price,
      mock_behavior: 'success'
    }
  end

  def mock_behavior
    'success'
  end

  def mock_success?
    true
  end
end
