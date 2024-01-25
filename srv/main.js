import pkg from 'pg'
const { Client } = pkg

export default cds.service.impl(async function () {
  this.on('updateMcis', 'Transport', async ({ params }) => {
    const ids = params.map((p) => p.id)
    console.log(`updating MCIs of Transports with ids ${JSON.stringify(ids)}`)

    const client = new Client()
    await client.connect()
    await client.query('CALL update_mcis_of_transports ($1);', [ids])
    await client.end()
  })
})
