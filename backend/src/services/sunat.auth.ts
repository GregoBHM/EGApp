import axios from 'axios';
import { env } from '../config/env';
import { decrypt } from '../utils/crypto';
import { db } from '../config/firebase';

interface TokenCache {
  token: string;
  expiresAt: number;
}

const tokenCacheMap = new Map<string, TokenCache>();

async function getAccessToken(id_empresa: string): Promise<string> {
  const cached = tokenCacheMap.get(id_empresa);
  if (cached && Date.now() < cached.expiresAt) {
    return cached.token;
  }

  const empresaDoc = await db.collection('empresas').doc(id_empresa).get();
  const data = empresaDoc.data();

  if (!data?.sunat_client_id || !data?.sunat_client_secret_enc) {
    throw new Error(`Empresa ${id_empresa} no tiene credenciales SUNAT configuradas.`);
  }

  const client_id = data.sunat_client_id as string;
  const client_secret = decrypt(data.sunat_client_secret_enc as string);

  const params = new URLSearchParams();
  params.append('grant_type', 'client_credentials');
  params.append('scope', 'https://api.sunat.gob.pe/v1/contribuyente/gem');

  const response = await axios.post(env.sunat.tokenUrl, params, {
    auth: { username: client_id, password: client_secret },
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });

  const token = response.data.access_token as string;
  const expiresIn = (response.data.expires_in as number) - 60;

  tokenCacheMap.set(id_empresa, {
    token,
    expiresAt: Date.now() + expiresIn * 1000,
  });

  return token;
}

export { getAccessToken };
