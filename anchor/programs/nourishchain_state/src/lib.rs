use anchor_lang::prelude::*;

declare_id!("AWyYvJCuYwn2FQvQj4P3nz3vmTgn8HgJBY6itReuy1pu");

const STATE_ACTIVE: u8 = 0;
const STATE_REVOKED: u8 = 1;
const STATE_REDEEMED: u8 = 2;

#[program]
pub mod nourishchain_state {
    use super::*;

    pub fn record_redeem(
        ctx: Context<RecordRedeem>,
        voucher_hash: [u8; 32],
        checkpoint_ref: [u8; 32],
    ) -> Result<()> {
        let clock = Clock::get()?;
        let record = &mut ctx.accounts.voucher_record;
        hydrate_record(record, voucher_hash, ctx.bumps.voucher_record);

        require!(record.state != STATE_REVOKED, VoucherStateError::VoucherRevoked);
        require!(record.state != STATE_REDEEMED, VoucherStateError::VoucherRedeemed);

        record.state = STATE_REDEEMED;
        record.last_action_at = clock.unix_timestamp;
        record.last_action_ref = checkpoint_ref;
        record.redeem_count = record
            .redeem_count
            .checked_add(1)
            .ok_or(VoucherStateError::CounterOverflow)?;

        emit!(RedeemRecorded {
            voucher_hash,
            checkpoint_ref,
            authority: ctx.accounts.authority.key(),
            recorded_at: clock.unix_timestamp,
        });

        Ok(())
    }

    pub fn record_revoke(
        ctx: Context<RecordRevoke>,
        voucher_hash: [u8; 32],
        checkpoint_ref: [u8; 32],
    ) -> Result<()> {
        let clock = Clock::get()?;
        let record = &mut ctx.accounts.voucher_record;
        hydrate_record(record, voucher_hash, ctx.bumps.voucher_record);

        require!(record.state != STATE_REDEEMED, VoucherStateError::VoucherRedeemed);

        record.state = STATE_REVOKED;
        record.last_action_at = clock.unix_timestamp;
        record.last_action_ref = checkpoint_ref;
        record.revoke_count = record
            .revoke_count
            .checked_add(1)
            .ok_or(VoucherStateError::CounterOverflow)?;

        emit!(RevokeRecorded {
            voucher_hash,
            checkpoint_ref,
            authority: ctx.accounts.authority.key(),
            recorded_at: clock.unix_timestamp,
        });

        Ok(())
    }

    pub fn log_override(
        ctx: Context<LogOverride>,
        voucher_hash: [u8; 32],
        override_ref: [u8; 32],
    ) -> Result<()> {
        let clock = Clock::get()?;
        let record = &mut ctx.accounts.voucher_record;
        hydrate_record(record, voucher_hash, ctx.bumps.voucher_record);

        record.last_action_at = clock.unix_timestamp;
        record.last_action_ref = override_ref;
        record.override_count = record
            .override_count
            .checked_add(1)
            .ok_or(VoucherStateError::CounterOverflow)?;

        emit!(OverrideLogged {
            voucher_hash,
            override_ref,
            authority: ctx.accounts.authority.key(),
            recorded_at: clock.unix_timestamp,
        });

        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(voucher_hash: [u8; 32], checkpoint_ref: [u8; 32])]
pub struct RecordRedeem<'info> {
    #[account(
        init_if_needed,
        payer = authority,
        space = 8 + VoucherRecord::INIT_SPACE,
        seeds = [b"voucher", voucher_hash.as_ref()],
        bump
    )]
    pub voucher_record: Account<'info, VoucherRecord>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(voucher_hash: [u8; 32], checkpoint_ref: [u8; 32])]
pub struct RecordRevoke<'info> {
    #[account(
        init_if_needed,
        payer = authority,
        space = 8 + VoucherRecord::INIT_SPACE,
        seeds = [b"voucher", voucher_hash.as_ref()],
        bump
    )]
    pub voucher_record: Account<'info, VoucherRecord>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(voucher_hash: [u8; 32], override_ref: [u8; 32])]
pub struct LogOverride<'info> {
    #[account(
        init_if_needed,
        payer = authority,
        space = 8 + VoucherRecord::INIT_SPACE,
        seeds = [b"voucher", voucher_hash.as_ref()],
        bump
    )]
    pub voucher_record: Account<'info, VoucherRecord>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[account]
#[derive(InitSpace)]
pub struct VoucherRecord {
    pub voucher_hash: [u8; 32],
    pub state: u8,
    pub bump: u8,
    pub last_action_at: i64,
    pub last_action_ref: [u8; 32],
    pub redeem_count: u32,
    pub revoke_count: u32,
    pub override_count: u32,
}

#[event]
pub struct RedeemRecorded {
    pub voucher_hash: [u8; 32],
    pub checkpoint_ref: [u8; 32],
    pub authority: Pubkey,
    pub recorded_at: i64,
}

#[event]
pub struct RevokeRecorded {
    pub voucher_hash: [u8; 32],
    pub checkpoint_ref: [u8; 32],
    pub authority: Pubkey,
    pub recorded_at: i64,
}

#[event]
pub struct OverrideLogged {
    pub voucher_hash: [u8; 32],
    pub override_ref: [u8; 32],
    pub authority: Pubkey,
    pub recorded_at: i64,
}

#[error_code]
pub enum VoucherStateError {
    #[msg("Voucher has already been revoked")]
    VoucherRevoked,
    #[msg("Voucher has already been redeemed")]
    VoucherRedeemed,
    #[msg("Counter overflow")]
    CounterOverflow,
}

fn hydrate_record(record: &mut VoucherRecord, voucher_hash: [u8; 32], bump: u8) {
    if record.voucher_hash == [0; 32] {
        record.voucher_hash = voucher_hash;
        record.state = STATE_ACTIVE;
        record.bump = bump;
        record.last_action_at = 0;
        record.last_action_ref = [0; 32];
        record.redeem_count = 0;
        record.revoke_count = 0;
        record.override_count = 0;
    }
}
