/* eslint-env mocha */
/* eslint-disable no-console */
/* global artifacts, contract, describe, it, expect */

const chai = require('chai')
const { assert } = chai
const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)

const EpochLibrary = artifacts.require('EpochLibrary.sol')
const AgreementStoreLibrary = artifacts.require('AgreementStoreLibrary.sol')
const ConditionStoreManager = artifacts.require('ConditionStoreManager.sol')
const TemplateStoreManager = artifacts.require('TemplateStoreManager.sol')
const AgreementStoreManager = artifacts.require('AgreementStoreManager.sol')
const constants = require('../../helpers/constants.js')

contract('AgreementStoreManager', (accounts) => {
    async function setupTest({
        agreementId = constants.bytes32.one,
        conditionIds = [constants.address.dummy],
        createRole = accounts[0],
        setupConditionStoreManager = true
    } = {}) {
        const epochLibrary = await EpochLibrary.new({ from: createRole })
        await ConditionStoreManager.link('EpochLibrary', epochLibrary.address)
        const conditionStoreManager = await ConditionStoreManager.new({ from: createRole })
        const templateStoreManager = await TemplateStoreManager.new({ from: createRole })
        const agreementStoreLibrary = await AgreementStoreLibrary.new({ from: createRole })
        await AgreementStoreManager.link('AgreementStoreLibrary', agreementStoreLibrary.address)
        const agreementStoreManager = await AgreementStoreManager.new()

        await agreementStoreManager.initialize(
            conditionStoreManager.address,
            templateStoreManager.address,
            { from: createRole }
        )

        if (setupConditionStoreManager) {
            await conditionStoreManager.setup(agreementStoreManager.address)
        }

        return {
            agreementStoreManager,
            conditionStoreManager,
            templateStoreManager,
            agreementId,
            conditionIds,
            createRole
        }
    }

    describe('deploy and setup', () => {
        it('contract should deploy', async () => {
            // act-assert
            const epochLibrary = await EpochLibrary.new({ from: accounts[0] })
            await ConditionStoreManager.link('EpochLibrary', epochLibrary.address)
            const conditionStoreManager = await ConditionStoreManager.new({ from: accounts[0] })
            const templateStoreManager = await TemplateStoreManager.new({ from: accounts[0] })

            const agreementStoreLibrary = await AgreementStoreLibrary.new({ from: accounts[0] })
            await AgreementStoreManager.link('AgreementStoreLibrary', agreementStoreLibrary.address)
            await AgreementStoreManager.new(
                conditionStoreManager.address,
                templateStoreManager.address,
                { from: accounts[0] }
            )
        })
    })

    describe('create agreement', () => {
        it('should create and agreement and conditions exist', async () => {
            const { agreementStoreManager, templateStoreManager, conditionStoreManager } = await setupTest()

            const templateId = constants.bytes32.one
            await templateStoreManager.createTemplate(
                templateId,
                [
                    constants.address.dummy,
                    accounts[0]
                ]
            )
            const storedTemplate = await templateStoreManager.getTemplate(templateId)

            const agreement = {
                did: constants.did[0],
                templateId: constants.bytes32.one,
                conditionIds: [constants.bytes32.zero, constants.bytes32.one],
                timeLocks: [0, 1],
                timeOuts: [2, 3]
            }
            const agreementId = constants.bytes32.one

            await agreementStoreManager.createAgreement(
                agreementId,
                ...Object.values(agreement)
            )

            expect(await agreementStoreManager.exists(agreementId)).to.equal(true)

            let storedCondition
            agreement.conditionIds.forEach(async (conditionId, i) => {
                storedCondition = await conditionStoreManager.getCondition(conditionId)
                expect(storedCondition.typeRef).to.equal(storedTemplate.conditionTypes[i])
                expect(storedCondition.state.toNumber()).to.equal(constants.condition.state.unfulfilled)
                expect(storedCondition.timeLock.toNumber()).to.equal(agreement.timeLocks[i])
                expect(storedCondition.timeOut.toNumber()).to.equal(agreement.timeOuts[i])
            })
        })

        it('should not create agreement with existing conditions', async () => {
            const { agreementStoreManager, templateStoreManager } = await setupTest()

            const templateId = constants.bytes32.one
            await templateStoreManager.createTemplate(
                templateId,
                [constants.address.dummy]
            )

            const agreement = {
                did: constants.did[0],
                templateId: constants.bytes32.one,
                conditionIds: [constants.bytes32.zero],
                timeLocks: [0],
                timeOuts: [2]
            }
            const agreementId = constants.bytes32.zero

            await agreementStoreManager.createAgreement(
                agreementId,
                ...Object.values(agreement)
            )

            const otherAgreement = {
                did: constants.did[0],
                templateId: constants.bytes32.one,
                conditionIds: [constants.bytes32.zero],
                timeLocks: [0],
                timeOuts: [2]
            }
            const otherAgreementId = constants.bytes32.one

            await assert.isRejected(
                agreementStoreManager.createAgreement(
                    otherAgreementId,
                    ...Object.values(otherAgreement)
                ),
                constants.condition.id.error.idAlreadyExists
            )
        })

        it('should not create agreement with non existing template', async () => {
            const { agreementStoreManager } = await setupTest()

            const agreement = {
                did: constants.did[0],
                templateId: constants.bytes32.one,
                conditionIds: [constants.bytes32.zero],
                timeLocks: [0],
                timeOuts: [2]
            }
            const agreementId = constants.bytes32.zero

            await assert.isRejected(
                agreementStoreManager.createAgreement(
                    agreementId,
                    ...Object.values(agreement)
                ),
                constants.template.error.templateMustExist
            )
        })
    })

    describe('get agreement', () => {
        it('successful create should get agreement', async () => {
            const { agreementStoreManager, templateStoreManager } = await setupTest()

            const templateId = constants.bytes32.one
            await templateStoreManager.createTemplate(
                templateId,
                [constants.address.dummy, accounts[0]]
            )

            const agreement = {
                did: constants.did[0],
                templateId: constants.bytes32.one,
                conditionIds: [constants.bytes32.one, constants.bytes32.zero],
                timeLocks: [0, 1],
                timeOuts: [2, 3]
            }
            const agreementId = constants.bytes32.one

            await agreementStoreManager.createAgreement(
                agreementId,
                ...Object.values(agreement)
            )

            // TODO - containSubset
            const storedAgreement = await agreementStoreManager.getAgreement(agreementId)
            expect(storedAgreement.did).to.equal(agreement.did)
            expect(storedAgreement.templateId).to.equal(agreement.templateId)
            expect(storedAgreement.conditionIds).to.deep.equal(agreement.conditionIds)
        })
    })

    describe('exists', () => {
        it('successful create should exist', async () => {
        })

        it('no create should not exist', async () => {
        })
    })
})